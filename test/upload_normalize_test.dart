import 'package:flutter_test/flutter_test.dart';
import 'package:qr_barcode_scanner/services/upload_service.dart';

void main() {
  test('normalizeServerUrl adds https and keeps final path', () {
    expect(
      UploadService.normalizeServerUrl('example.com/upload'),
      'https://example.com/upload',
    );
    expect(
      UploadService.normalizeServerUrl('https://example.com/upload'),
      'https://example.com/upload',
    );
    expect(
      UploadService.normalizeServerUrl('http://example.com/upload'),
      'https://example.com/upload',
    );
  });

  test('normalizeApiKey strips quotes and spaces', () {
    expect(UploadService.normalizeApiKey(" demo-key' "), 'demo-key');
    expect(UploadService.normalizeApiKey('"demo-key"'), 'demo-key');
    expect(UploadService.normalizeApiKey('demo-key'), 'demo-key');
  });

  test('isSameAuthScope requires matching host scheme and port', () {
    final origin = Uri.parse('https://api.example.com/upload');
    expect(
      UploadService.isSameAuthScope(
        origin,
        Uri.parse('https://api.example.com/v2'),
      ),
      isTrue,
    );
    expect(
      UploadService.isSameAuthScope(
        origin,
        Uri.parse('https://evil.example/steal'),
      ),
      isFalse,
    );
    expect(
      UploadService.isSameAuthScope(
        origin,
        Uri.parse('http://api.example.com/upload'),
      ),
      isFalse,
    );
  });
}
