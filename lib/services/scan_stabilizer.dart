/// Requires the same payload across multiple detections before accepting.
///
/// Used because mobile_scanner exposes no confidence score; a single flaky
/// decode can otherwise be persisted immediately.
class ScanStabilizer {
  ScanStabilizer({
    this.requiredHits = 3,
    this.window = const Duration(milliseconds: 500),
  }) : assert(requiredHits >= 1);

  final int requiredHits;
  final Duration window;

  String? _candidate;
  int _hits = 0;
  DateTime? _firstHitAt;

  /// Feed a detected [value]. Returns it when consensus is reached, else null.
  String? add(String value, {DateTime? now}) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;

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
