import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

import '../constants/api_contract.dart';
import '../models/scan_record.dart';
import 'settings_service.dart';

class UploadResult {
  const UploadResult({
    required this.status,
    this.message,
  });

  final UploadStatus status;
  final String? message;

  bool get isSuccess => status == UploadStatus.sent;
}

class UploadService {
  UploadService(this._settings);

  final SettingsService _settings;

  /// Normalize pasted URLs like `www.ayunts.com/...` → `https://www.ayunts.com/...`
  static String normalizeServerUrl(String raw) {
    var url = raw.trim();
    if (url.isEmpty) return url;
    if (!url.contains('://')) {
      url = 'https://$url';
    }
    final uri = Uri.tryParse(url);
    if (uri != null && uri.scheme == 'http' && uri.host.isNotEmpty) {
      url = uri.replace(scheme: 'https').toString();
    }
    return url;
  }

  /// Strip accidental quotes/spaces from keys like `[REDACTED]'`.
  static String normalizeApiKey(String raw) {
    return raw.trim().replaceAll(RegExp(r'''^['"]+|['"]+$'''), '');
  }

  Future<UploadResult> uploadScan(ScanRecord record, {bool retry = true}) async {
    if (!_settings.uploadEnabled) {
      return const UploadResult(
        status: UploadStatus.skipped,
        message: 'Upload is disabled',
      );
    }

    final url = normalizeServerUrl(_settings.serverUrl);
    final uri = Uri.tryParse(url);
    if (url.isEmpty || uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return const UploadResult(
        status: UploadStatus.skipped,
        message: 'Configure a valid server URL in Settings',
      );
    }

    final payload = ApiContract.buildPayload(
      value: record.value,
      format: record.format,
      scannedAt: record.scannedAt,
      source: record.source,
      deviceId: _settings.deviceId,
    );

    try {
      final response = await _postJson(uri, payload);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return const UploadResult(status: UploadStatus.sent, message: 'Sent');
      }
      final noRetry = response.statusCode == 401 ||
          response.statusCode == 403 ||
          response.statusCode == 404 ||
          response.statusCode == 405;
      if (retry && !noRetry) {
        return uploadScan(record, retry: false);
      }
      return UploadResult(
        status: UploadStatus.failed,
        message: _formatError(response.statusCode, response.body),
      );
    } on TimeoutException catch (_) {
      return const UploadResult(
        status: UploadStatus.failed,
        message:
            'Server timed out. Check internet, use https://example.com/your-upload-endpoint, and API key [REDACTED]',
      );
    } on SocketException catch (error) {
      return UploadResult(
        status: UploadStatus.failed,
        message: 'Network error: ${error.message}',
      );
    } catch (error) {
      if (retry) {
        return uploadScan(record, retry: false);
      }
      final text = error.toString();
      if (text.contains('TimeoutException')) {
        return const UploadResult(
          status: UploadStatus.failed,
          message:
              'Server timed out. Check internet and the server URL/API key, then try again',
        );
      }
      return UploadResult(
        status: UploadStatus.failed,
        message: text,
      );
    }
  }

  Future<UploadResult> testConnection() async {
    final sample = ScanRecord(
      id: 'test',
      value: 'https://example.com',
      format: 'qr_code',
      scannedAt: DateTime.now().toUtc(),
      source: 'camera',
    );
    return uploadScan(sample, retry: false);
  }

  /// POST JSON with Content-Length (avoids chunked-body hangs on some PHP hosts)
  /// and re-POST across redirects (avoids GET→405).
  Future<({int statusCode, String body})> _postJson(
    Uri uri,
    Map<String, dynamic> payload,
  ) async {
    final httpClient = HttpClient()
      ..connectionTimeout = const Duration(seconds: 12)
      ..idleTimeout = const Duration(seconds: 12);
    final client = IOClient(httpClient);

    try {
      var current = uri;
      final body = jsonEncode(payload);
      final key = normalizeApiKey(_settings.apiKey);

      for (var hop = 0; hop < 5; hop++) {
        final request = http.Request('POST', current)
          ..followRedirects = false
          ..headers[HttpHeaders.contentTypeHeader] = 'application/json; charset=utf-8'
          ..headers[HttpHeaders.acceptHeader] = 'application/json'
          ..headers[HttpHeaders.connectionHeader] = 'close'
          ..body = body;

        if (key.isNotEmpty) {
          request.headers[HttpHeaders.authorizationHeader] =
              key.toLowerCase().startsWith('bearer ') ? key : 'Bearer $key';
        }

        final streamed = await client
            .send(request)
            .timeout(const Duration(seconds: 15));
        final response = await http.Response.fromStream(streamed)
            .timeout(const Duration(seconds: 15));

        final code = response.statusCode;
        if (code >= 300 && code < 400) {
          final location = response.headers['location'];
          if (location == null || location.isEmpty) {
            return (statusCode: code, body: response.body);
          }
          current = current.resolve(location);
          continue;
        }

        return (statusCode: code, body: response.body);
      }

      return (
        statusCode: 310,
        body:
            '{"error":"Too many redirects. Use https://example.com/your-upload-endpoint"}',
      );
    } finally {
      client.close();
    }
  }

  String _formatError(int statusCode, String body) {
    String? serverMessage;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['error'] != null) {
        serverMessage = decoded['error'].toString();
      } else if (decoded is Map && decoded['message'] != null) {
        serverMessage = decoded['message'].toString();
      }
    } catch (_) {
      if (body.trim().isNotEmpty && body.length < 180) {
        serverMessage = body.trim();
      }
    }

    final hint = switch (statusCode) {
      401 => 'Wrong API key — use [REDACTED]',
      405 =>
        'Server rejected method. Use https://example.com/your-upload-endpoint',
      404 => 'URL not found — check the full path to your PHP script',
      _ => null,
    };

    final parts = <String>[
      'HTTP $statusCode',
      if (serverMessage != null && serverMessage.isNotEmpty) serverMessage,
      if (hint != null) hint,
    ];
    return parts.join(' — ');
  }
}
