import 'scan_record.dart';

class ScanOutcome {
  const ScanOutcome({
    required this.record,
    required this.isDuplicate,
  });

  final ScanRecord record;
  final bool isDuplicate;
}
