import 'package:hive_ce_flutter/hive_flutter.dart';

import '../models/scan_record.dart';

class HistoryService {
  HistoryService(this._box);

  static const boxName = 'scan_history';
  final Box<dynamic> _box;

  static Future<HistoryService> open() async {
    final box = await Hive.openBox<dynamic>(boxName);
    return HistoryService(box);
  }

  List<ScanRecord> getAll() {
    final records = _box.values
        .whereType<Map>()
        .map((item) => ScanRecord.fromMap(Map<dynamic, dynamic>.from(item)))
        .toList();
    records.sort((a, b) => b.scannedAt.compareTo(a.scannedAt));
    return records;
  }

  Future<void> upsert(ScanRecord record) async {
    await _box.put(record.id, record.toMap());
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  Future<void> clear() async {
    await _box.clear();
  }

  Future<void> updateUploadStatus(String id, UploadStatus status) async {
    final raw = _box.get(id);
    if (raw is! Map) return;
    final record = ScanRecord.fromMap(Map<dynamic, dynamic>.from(raw));
    await upsert(record.copyWith(uploadStatus: status));
  }
}
