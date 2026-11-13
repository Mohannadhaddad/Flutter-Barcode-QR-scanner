import 'package:flutter_test/flutter_test.dart';
import 'package:qr_barcode_scanner/models/scan_record.dart';

void main() {
  test('round-trips through map', () {
    final record = ScanRecord(
      id: '1',
      value: 'https://example.com',
      format: 'qr_code',
      scannedAt: DateTime.utc(2026, 1, 2, 3, 4, 5),
      source: 'gallery',
      uploadStatus: UploadStatus.sent,
    );

    final restored = ScanRecord.fromMap(record.toMap());
    expect(restored.id, record.id);
    expect(restored.value, record.value);
    expect(restored.format, record.format);
    expect(restored.source, record.source);
    expect(restored.uploadStatus, UploadStatus.sent);
    expect(restored.isUrl, isTrue);
  });
}
