import 'dart:convert';

import 'package:http/http.dart' as http;

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
  UploadService(this._settings, {http.Client? client})
      : _client = client ?? http.Client();

  final SettingsService _settings;
  final http.Client _client;

  Future<UploadResult> uploadScan(ScanRecord record, {bool retry = true}) async {
    if (!_settings.uploadEnabled) {
      return const UploadResult(
        status: UploadStatus.skipped,
        message: 'Upload is disabled',
      );
    }

    final url = _settings.serverUrl;
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
      final response = await _post(uri, payload);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return const UploadResult(status: UploadStatus.sent, message: 'Sent');
      }
      if (retry) {
        return uploadScan(record, retry: false);
      }
      return UploadResult(
        status: UploadStatus.failed,
        message: 'Server responded ${response.statusCode}',
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

  Future<http.Response> _post(Uri uri, Map<String, dynamic> payload) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    final key = _settings.apiKey;
    if (key.isNotEmpty) {
      headers['Authorization'] = 'Bearer $key';
    }
    return _client
        .post(uri, headers: headers, body: jsonEncode(payload))
        .timeout(const Duration(seconds: 12));
  }
}
