import 'package:flutter_test/flutter_test.dart';
import 'package:qr_barcode_scanner/services/upload_service.dart';

void main() {
  test('normalizeServerUrl adds https and keeps final path', () {
    expect(
      UploadService.normalizeServerUrl('example.com/your-upload-endpoint'),
      'https://example.com/your-upload-endpoint',
    );
    expect(
      UploadService.normalizeServerUrl(
        'https://example.com/your-upload-endpoint',
      ),
      'https://example.com/your-upload-endpoint',
    );
    expect(
      UploadService.normalizeServerUrl(
        'https://example.com/your-upload-endpoint',
      ),
      'https://example.com/your-upload-endpoint',
    );
  });

  test('normalizeApiKey strips quotes and spaces', () {
    expect(UploadService.normalizeApiKey(" [REDACTED]' "), '[REDACTED]');
    expect(UploadService.normalizeApiKey('"[REDACTED]"'), '[REDACTED]');
    expect(UploadService.normalizeApiKey('[REDACTED]'), '[REDACTED]');
  });
}
