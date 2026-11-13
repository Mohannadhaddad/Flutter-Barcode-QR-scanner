import 'dart:convert';
import 'dart:io';

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
    // Users often paste without scheme.
    if (!url.contains('://')) {
      url = 'https://$url';
    }
    // Prefer https for bare http hosts that always redirect.
    final uri = Uri.tryParse(url);
    if (uri != null && uri.scheme == 'http' && uri.host.isNotEmpty) {
      url = uri.replace(scheme: 'https').toString();
    }
    return url;
  }

  /// Strip accidental quotes/spaces from keys like `3535'`.
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
      // Auth / method errors won't succeed on retry — fail fast.
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
    } catch (error) {
      if (retry) {
        return uploadScan(record, retry: false);
      }
      return UploadResult(
        status: UploadStatus.failed,
        message: error.toString(),
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

  /// POST JSON without converting POST→GET on 301/302 redirects (common 405 cause).
  Future<({int statusCode, String body})> _postJson(
    Uri uri,
    Map<String, dynamic> payload,
  ) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 8);
    try {
      var current = uri;
      for (var hop = 0; hop < 5; hop++) {
        final request = await client.postUrl(current);
        request.followRedirects = false;
        request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
        request.headers.set(HttpHeaders.acceptHeader, 'application/json');

        final key = normalizeApiKey(_settings.apiKey);
        if (key.isNotEmpty) {
          final token = key.toLowerCase().startsWith('bearer ')
              ? key
              : 'Bearer $key';
          request.headers.set(HttpHeaders.authorizationHeader, token);
        }

        request.add(utf8.encode(jsonEncode(payload)));
        final response =
            await request.close().timeout(const Duration(seconds: 8));
        final body = await response.transform(utf8.decoder).join();

        final code = response.statusCode;
        if (code >= 300 && code < 400) {
          final location = response.headers.value(HttpHeaders.locationHeader);
          if (location == null || location.isEmpty) {
            return (statusCode: code, body: body);
          }
          current = current.resolve(location);
          continue;
        }

        return (statusCode: code, body: body);
      }
      return (
        statusCode: 310,
        body: '{"error":"Too many redirects. Use https://www.ayunts.com/qrScanner/scan.php"}',
      );
    } finally {
      client.close(force: true);
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
      401 => 'Wrong API key — use the key from your PHP (e.g. 3535)',
      405 =>
        'Server rejected method. Use https://www.ayunts.com/qrScanner/scan.php',
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
