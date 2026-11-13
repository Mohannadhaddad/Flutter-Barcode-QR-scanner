import 'package:flutter_test/flutter_test.dart';
import 'package:qr_barcode_scanner/models/scan_record.dart';

void main() {
  test('duplicate cooldown matches recent identical values', () {
    final now = DateTime.utc(2026, 11, 13, 12, 0, 0);
    final records = [
      ScanRecord(
        id: '1',
        value: 'ABC',
        format: 'qr_code',
        scannedAt: now.subtract(const Duration(seconds: 60)),
        source: 'camera',
      ),
      ScanRecord(
        id: '2',
        value: 'XYZ',
        format: 'qr_code',
        scannedAt: now,
        source: 'camera',
      ),
    ];

    ScanRecord? findDuplicate({
      required String value,
      required int cooldownSeconds,
    }) {
      for (final record in records) {
        if (record.value.trim() != value.trim()) continue;
        if (cooldownSeconds <= 0) return record;
        final age = now.difference(record.scannedAt.toUtc());
        if (age <= Duration(seconds: cooldownSeconds)) return record;
      }
      return null;
    }

    expect(findDuplicate(value: 'ABC', cooldownSeconds: 300)?.id, '1');
    expect(findDuplicate(value: 'ABC', cooldownSeconds: 30), isNull);
    expect(findDuplicate(value: 'ABC', cooldownSeconds: 0)?.id, '1');
    expect(findDuplicate(value: 'XYZ', cooldownSeconds: 30)?.id, '2');
  });
}
