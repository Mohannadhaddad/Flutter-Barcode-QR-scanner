import 'dart:async';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/scan_record.dart';
import '../services/feedback_service.dart';
import '../services/history_service.dart';
import '../services/settings_service.dart';
import '../services/upload_service.dart';

class AppState extends ChangeNotifier {
  AppState({
    required SettingsService settings,
    required HistoryService history,
    required UploadService upload,
    FeedbackService? feedback,
  })  : _settings = settings,
        _history = history,
        _upload = upload,
        _feedback = feedback ?? FeedbackService() {
    _records = _history.getAll();
  }

  final SettingsService _settings;
  final HistoryService _history;
  final UploadService _upload;
  final FeedbackService _feedback;

  late List<ScanRecord> _records;
  String _historyQuery = '';

  SettingsService get settings => _settings;
  UploadService get upload => _upload;
  List<ScanRecord> get records => List.unmodifiable(_records);
  String get historyQuery => _historyQuery;

  List<ScanRecord> get filteredRecords {
    final query = _historyQuery.trim().toLowerCase();
    if (query.isEmpty) return records;
    return _records
        .where(
          (record) =>
              record.value.toLowerCase().contains(query) ||
              record.format.toLowerCase().contains(query),
        )
        .toList();
  }

  ThemeMode get themeMode {
    switch (_settings.themeMode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<ScanRecord> handleScan({
    required String value,
    required String format,
    required String source,
    bool playFeedback = true,
  }) async {
    final record = ScanRecord(
      id: const Uuid().v4(),
      value: value,
      format: format,
      scannedAt: DateTime.now().toUtc(),
      source: source,
      uploadStatus: _settings.uploadEnabled
          ? UploadStatus.pending
          : UploadStatus.skipped,
    );

    await _history.upsert(record);
    _records = _history.getAll();
    notifyListeners();

    if (playFeedback) {
      await _feedback.playSuccess(
        beep: _settings.beepEnabled,
        vibrate: _settings.vibrateEnabled,
      );
    }

    if (_settings.autoCopy) {
      // Clipboard copy is performed by the UI layer with services.
    }

    // Upload in the background so the result screen opens immediately.
    if (_settings.uploadEnabled) {
      unawaited(_uploadInBackground(record));
    }

    return record;
  }

  Future<void> _uploadInBackground(ScanRecord record) async {
    final result = await _upload.uploadScan(record);
    await _history.updateUploadStatus(record.id, result.status);
    _records = _history.getAll();
    notifyListeners();
  }

  Future<UploadResult> retryUpload(ScanRecord record) async {
    await _history.updateUploadStatus(record.id, UploadStatus.pending);
    _records = _history.getAll();
    notifyListeners();

    final result = await _upload.uploadScan(record);
    await _history.updateUploadStatus(record.id, result.status);
    _records = _history.getAll();
    notifyListeners();
    return result;
  }

  Future<void> deleteRecord(String id) async {
    await _history.delete(id);
    _records = _history.getAll();
    notifyListeners();
  }

  Future<void> clearHistory() async {
    await _history.clear();
    _records = [];
    notifyListeners();
  }

  void setHistoryQuery(String value) {
    _historyQuery = value;
    notifyListeners();
  }

  Future<void> setContinuousScan(bool value) async {
    await _settings.setContinuousScan(value);
    notifyListeners();
  }

  Future<void> setBeepEnabled(bool value) async {
    await _settings.setBeepEnabled(value);
    notifyListeners();
  }

  Future<void> setVibrateEnabled(bool value) async {
    await _settings.setVibrateEnabled(value);
    notifyListeners();
  }

  Future<void> setAutoCopy(bool value) async {
    await _settings.setAutoCopy(value);
    notifyListeners();
  }

  Future<void> setThemeMode(String value) async {
    await _settings.setThemeMode(value);
    notifyListeners();
  }

  Future<void> setUploadEnabled(bool value) async {
    await _settings.setUploadEnabled(value);
    notifyListeners();
  }

  Future<void> setServerUrl(String value) async {
    await _settings.setServerUrl(value.trim());
    notifyListeners();
  }

  Future<void> setApiKey(String value) async {
    await _settings.setApiKey(UploadService.normalizeApiKey(value));
    notifyListeners();
  }

  ScanRecord? findById(String id) {
    try {
      return _records.firstWhere((record) => record.id == id);
    } catch (_) {
      return null;
    }
  }
}
