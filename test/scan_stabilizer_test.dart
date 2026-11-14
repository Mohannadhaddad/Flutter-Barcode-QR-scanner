import 'package:flutter_test/flutter_test.dart';
import 'package:qr_barcode_scanner/services/scan_stabilizer.dart';

void main() {
  group('ScanStabilizer', () {
    test('requires repeated matching hits within the window', () {
      final stabilizer = ScanStabilizer(
        requiredHits: 3,
        window: const Duration(milliseconds: 500),
      );
      final t0 = DateTime.utc(2026, 11, 14, 12);

      expect(stabilizer.add('ABC', now: t0), isNull);
      expect(
        stabilizer.add('ABC', now: t0.add(const Duration(milliseconds: 100))),
        isNull,
      );
      expect(
        stabilizer.add('ABC', now: t0.add(const Duration(milliseconds: 200))),
        'ABC',
      );
    });

    test('resets when a different value appears', () {
      final stabilizer = ScanStabilizer(
        requiredHits: 3,
        window: const Duration(milliseconds: 500),
      );
      final t0 = DateTime.utc(2026, 11, 14, 12);

      expect(stabilizer.add('ABC', now: t0), isNull);
      expect(
        stabilizer.add('ABC', now: t0.add(const Duration(milliseconds: 50))),
        isNull,
      );
      expect(
        stabilizer.add('ABO', now: t0.add(const Duration(milliseconds: 100))),
        isNull,
      );
      expect(
        stabilizer.add('ABO', now: t0.add(const Duration(milliseconds: 150))),
        isNull,
      );
      expect(
        stabilizer.add('ABO', now: t0.add(const Duration(milliseconds: 200))),
        'ABO',
      );
    });

    test('resets when the consensus window expires', () {
      final stabilizer = ScanStabilizer(
        requiredHits: 3,
        window: const Duration(milliseconds: 500),
      );
      final t0 = DateTime.utc(2026, 11, 14, 12);

      expect(stabilizer.add('ABC', now: t0), isNull);
      expect(
        stabilizer.add('ABC', now: t0.add(const Duration(milliseconds: 100))),
        isNull,
      );
      expect(
        stabilizer.add('ABC', now: t0.add(const Duration(milliseconds: 600))),
        isNull,
      );
      expect(
        stabilizer.add('ABC', now: t0.add(const Duration(milliseconds: 700))),
        isNull,
      );
      expect(
        stabilizer.add('ABC', now: t0.add(const Duration(milliseconds: 800))),
        'ABC',
      );
    });

    test('trims whitespace and ignores empty values', () {
      final stabilizer = ScanStabilizer(requiredHits: 2);
      final t0 = DateTime.utc(2026, 11, 14, 12);

      expect(stabilizer.add('  ', now: t0), isNull);
      expect(stabilizer.add('  ABC  ', now: t0), isNull);
      expect(
        stabilizer.add('ABC', now: t0.add(const Duration(milliseconds: 10))),
        'ABC',
      );
    });

    test('reset clears partial consensus', () {
      final stabilizer = ScanStabilizer(requiredHits: 3);
      final t0 = DateTime.utc(2026, 11, 14, 12);

      expect(stabilizer.add('ABC', now: t0), isNull);
      stabilizer.reset();
      expect(
        stabilizer.add('ABC', now: t0.add(const Duration(milliseconds: 10))),
        isNull,
      );
    });
  });
}
