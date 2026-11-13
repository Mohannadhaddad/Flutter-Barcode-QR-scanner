import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

class SettingsService {
  SettingsService(this._box);

  static const boxName = 'settings';
  final Box<dynamic> _box;

  static Future<SettingsService> open() async {
    final box = await Hive.openBox<dynamic>(boxName);
    final service = SettingsService(box);
    await service._ensureDeviceId();
    return service;
  }

  Future<void> _ensureDeviceId() async {
    if ((_box.get('deviceId') as String?)?.isNotEmpty != true) {
      await _box.put('deviceId', const Uuid().v4());
    }
  }

  String get deviceId => _box.get('deviceId') as String? ?? 'unknown-device';

  bool get continuousScan => _box.get('continuousScan', defaultValue: false) as bool;
  Future<void> setContinuousScan(bool value) => _box.put('continuousScan', value);

  bool get beepEnabled => _box.get('beepEnabled', defaultValue: true) as bool;
  Future<void> setBeepEnabled(bool value) => _box.put('beepEnabled', value);

  bool get vibrateEnabled =>
      _box.get('vibrateEnabled', defaultValue: true) as bool;
  Future<void> setVibrateEnabled(bool value) =>
      _box.put('vibrateEnabled', value);

  bool get autoCopy => _box.get('autoCopy', defaultValue: false) as bool;
  Future<void> setAutoCopy(bool value) => _box.put('autoCopy', value);

  String get themeMode => _box.get('themeMode', defaultValue: 'system') as String;
  Future<void> setThemeMode(String value) => _box.put('themeMode', value);

  bool get uploadEnabled =>
      _box.get('uploadEnabled', defaultValue: false) as bool;
  Future<void> setUploadEnabled(bool value) => _box.put('uploadEnabled', value);

  String get serverUrl => _box.get('serverUrl', defaultValue: '') as String;
  Future<void> setServerUrl(String value) => _box.put('serverUrl', value.trim());

  String get apiKey => _box.get('apiKey', defaultValue: '') as String;
  Future<void> setApiKey(String value) => _box.put('apiKey', value.trim());
}
