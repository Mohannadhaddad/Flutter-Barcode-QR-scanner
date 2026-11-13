import 'package:flutter_test/flutter_test.dart';
import 'package:qr_barcode_scanner/services/upload_service.dart';

void main() {
  test('normalizeServerUrl adds https and keeps final path', () {
    expect(
      UploadService.normalizeServerUrl('www.ayunts.com/qrScanner/scan.php'),
      'https://www.ayunts.com/qrScanner/scan.php',
    );
    expect(
      UploadService.normalizeServerUrl(
        'https://www.ayunts.com/qrScanner/scan.php',
      ),
      'https://www.ayunts.com/qrScanner/scan.php',
    );
    expect(
      UploadService.normalizeServerUrl(
        'http://www.ayunts.com/qrScanner/scan.php',
      ),
      'https://www.ayunts.com/qrScanner/scan.php',
    );
  });

  test('normalizeApiKey strips quotes and spaces', () {
    expect(UploadService.normalizeApiKey(" 3535' "), '3535');
    expect(UploadService.normalizeApiKey('"3535"'), '3535');
    expect(UploadService.normalizeApiKey('3535'), '3535');
  });
}
