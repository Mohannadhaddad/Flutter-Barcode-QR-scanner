import 'package:flutter_test/flutter_test.dart';
import 'package:qr_barcode_scanner/services/scan_stabilizer.dart';

void main() {
  group('ScanStabilizer', () {
    test('2D formats accept on the first hit', () {
      final stabilizer = ScanStabilizer();
      final t0 = DateTime.utc(2026, 11, 14, 12);

      expect(
        stabilizer.add('https://example.com', format: 'qrCode', now: t0),
        'https://example.com',
      );
      expect(
        ScanStabilizer().add('ABC', format: 'qr_code', now: t0),
        'ABC',
      );
      expect(
        ScanStabilizer().add('XYZ', format: 'aztec', now: t0),
        'XYZ',
      );
      expect(
        ScanStabilizer().add('DM', format: 'data_matrix', now: t0),
        'DM',
      );
    });

    test('1D formats require two matching hits within the window', () {
      final stabilizer = ScanStabilizer();
      final t0 = DateTime.utc(2026, 11, 14, 12);

      expect(stabilizer.add('ABC', format: 'code128', now: t0), isNull);
      expect(
        stabilizer.add(
          'ABC',
          format: 'code128',
          now: t0.add(const Duration(milliseconds: 100)),
        ),
        'ABC',
      );
    });

    test('1D resets when a different value appears', () {
      final stabilizer = ScanStabilizer();
      final t0 = DateTime.utc(2026, 11, 14, 12);

      expect(stabilizer.add('ABC', format: 'ean13', now: t0), isNull);
      expect(
        stabilizer.add(
          'ABO',
          format: 'ean13',
          now: t0.add(const Duration(milliseconds: 50)),
        ),
        isNull,
      );
      expect(
        stabilizer.add(
          'ABO',
          format: 'ean13',
          now: t0.add(const Duration(milliseconds: 100)),
        ),
        'ABO',
      );
    });

    test('1D resets when the consensus window expires', () {
      final stabilizer = ScanStabilizer(
        window: const Duration(milliseconds: 350),
      );
      final t0 = DateTime.utc(2026, 11, 14, 12);

      expect(stabilizer.add('ABC', format: 'code39', now: t0), isNull);
      expect(
        stabilizer.add(
          'ABC',
          format: 'code39',
          now: t0.add(const Duration(milliseconds: 400)),
        ),
        isNull,
      );
      expect(
        stabilizer.add(
          'ABC',
          format: 'code39',
          now: t0.add(const Duration(milliseconds: 450)),
        ),
        'ABC',
      );
    });

    test('trims whitespace and ignores empty values', () {
      final stabilizer = ScanStabilizer();
      final t0 = DateTime.utc(2026, 11, 14, 12);

      expect(stabilizer.add('  ', format: 'code128', now: t0), isNull);
      expect(stabilizer.add('  ABC  ', format: 'code128', now: t0), isNull);
      expect(
        stabilizer.add(
          'ABC',
          format: 'code128',
          now: t0.add(const Duration(milliseconds: 10)),
        ),
        'ABC',
      );
    });

    test('is2dFormat recognizes common names', () {
      expect(ScanStabilizer.is2dFormat('qrCode'), isTrue);
      expect(ScanStabilizer.is2dFormat('qr_code'), isTrue);
      expect(ScanStabilizer.is2dFormat('aztec'), isTrue);
      expect(ScanStabilizer.is2dFormat('dataMatrix'), isTrue);
      expect(ScanStabilizer.is2dFormat('code128'), isFalse);
      expect(ScanStabilizer.is2dFormat('ean_13'), isFalse);
      expect(ScanStabilizer.requiredHitsFor('qrCode'), 1);
      expect(ScanStabilizer.requiredHitsFor('code128'), 2);
    });

    test('reset clears partial consensus', () {
      final stabilizer = ScanStabilizer();
      final t0 = DateTime.utc(2026, 11, 14, 12);

      expect(stabilizer.add('ABC', format: 'code128', now: t0), isNull);
      stabilizer.reset();
      expect(
        stabilizer.add(
          'ABC',
          format: 'code128',
          now: t0.add(const Duration(milliseconds: 10)),
        ),
        isNull,
      );
    });
  });
}
