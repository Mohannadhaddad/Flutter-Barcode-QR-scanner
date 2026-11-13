import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

class SettingsService {
  SettingsService(this._box, this._secureStorage);

  static const boxName = 'settings';
  static const _apiKeySecureKey = 'apiKey';

  final Box<dynamic> _box;
  final FlutterSecureStorage _secureStorage;

  String _apiKey = '';

  static Future<SettingsService> open({
    FlutterSecureStorage? secureStorage,
  }) async {
    final box = await Hive.openBox<dynamic>(boxName);
    final storage = secureStorage ??
        const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
        );
    final service = SettingsService(box, storage);
    await service._ensureDeviceId();
    await service._loadAndMigrateApiKey();
    return service;
  }

  Future<void> _ensureDeviceId() async {
    if ((_box.get('deviceId') as String?)?.isNotEmpty != true) {
      await _box.put('deviceId', const Uuid().v4());
    }
  }

  /// Prefer secure storage; migrate any legacy Hive plaintext key once.
  Future<void> _loadAndMigrateApiKey() async {
    final secure = (await _secureStorage.read(key: _apiKeySecureKey)) ?? '';
    if (secure.isNotEmpty) {
      _apiKey = secure;
      if (_box.containsKey('apiKey')) {
        await _box.delete('apiKey');
      }
      return;
    }

    final legacy = (_box.get('apiKey') as String?)?.trim() ?? '';
    if (legacy.isNotEmpty) {
      _apiKey = legacy;
      await _secureStorage.write(key: _apiKeySecureKey, value: legacy);
      await _box.delete('apiKey');
      return;
    }

    _apiKey = '';
  }

  String get deviceId => _box.get('deviceId') as String? ?? 'unknown-device';

  bool get continuousScan =>
      _box.get('continuousScan', defaultValue: false) as bool;
  Future<void> setContinuousScan(bool value) =>
      _box.put('continuousScan', value);

  bool get beepEnabled => _box.get('beepEnabled', defaultValue: true) as bool;
  Future<void> setBeepEnabled(bool value) => _box.put('beepEnabled', value);

  bool get vibrateEnabled =>
      _box.get('vibrateEnabled', defaultValue: true) as bool;
  Future<void> setVibrateEnabled(bool value) =>
      _box.put('vibrateEnabled', value);

  bool get autoCopy => _box.get('autoCopy', defaultValue: false) as bool;
  Future<void> setAutoCopy(bool value) => _box.put('autoCopy', value);

  /// Skip saving/uploading the same code again within [duplicateCooldownSeconds].
  bool get preventDuplicates =>
      _box.get('preventDuplicates', defaultValue: true) as bool;
  Future<void> setPreventDuplicates(bool value) =>
      _box.put('preventDuplicates', value);

  /// 0 = for the whole app session (until app restart / clear history).
  int get duplicateCooldownSeconds =>
      _box.get('duplicateCooldownSeconds', defaultValue: 300) as int;
  Future<void> setDuplicateCooldownSeconds(int value) =>
      _box.put('duplicateCooldownSeconds', value);

  String get themeMode =>
      _box.get('themeMode', defaultValue: 'system') as String;
  Future<void> setThemeMode(String value) => _box.put('themeMode', value);

  bool get uploadEnabled =>
      _box.get('uploadEnabled', defaultValue: false) as bool;
  Future<void> setUploadEnabled(bool value) =>
      _box.put('uploadEnabled', value);

  String get serverUrl => _box.get('serverUrl', defaultValue: '') as String;
  Future<void> setServerUrl(String value) =>
      _box.put('serverUrl', value.trim());

  String get apiKey => _apiKey;

  Future<void> setApiKey(String value) async {
    final trimmed = value.trim();
    _apiKey = trimmed;
    if (trimmed.isEmpty) {
      await _secureStorage.delete(key: _apiKeySecureKey);
    } else {
      await _secureStorage.write(key: _apiKeySecureKey, value: trimmed);
    }
    if (_box.containsKey('apiKey')) {
      await _box.delete('apiKey');
    }
  }
}
