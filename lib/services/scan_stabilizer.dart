/// Requires matching payload hits before accepting when the stable scan filter
/// is enabled. 2D codes (QR / Aztec / Data Matrix) accept on the first hit;
/// 1D codes need two matching hits within [window].
class ScanStabilizer {
  ScanStabilizer({
    this.window = const Duration(milliseconds: 350),
  });

  final Duration window;

  String? _candidate;
  int _hits = 0;
  DateTime? _firstHitAt;

  /// True for formats with strong error correction (instant accept).
  static bool is2dFormat(String? format) {
    final normalized = (format ?? '').toLowerCase().replaceAll('_', '');
    return normalized.contains('qr') ||
        normalized.contains('aztec') ||
        normalized.contains('datamatrix');
  }

  static int requiredHitsFor(String? format) => is2dFormat(format) ? 1 : 2;

  /// Feed a detected [value]. Returns it when consensus is reached, else null.
  String? add(String value, {String? format, DateTime? now}) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;

    final requiredHits = requiredHitsFor(format);
    final at = now ?? DateTime.now();

    if (_candidate == null ||
        _candidate != trimmed ||
        _firstHitAt == null ||
        at.difference(_firstHitAt!) > window) {
      _candidate = trimmed;
      _hits = 1;
      _firstHitAt = at;
      return requiredHits <= 1 ? trimmed : null;
    }

    _hits += 1;
    if (_hits >= requiredHits) {
      reset();
      return trimmed;
    }
    return null;
  }

  void reset() {
    _candidate = null;
    _hits = 0;
    _firstHitAt = null;
  }
}
