import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'providers/app_state.dart';
import 'services/history_service.dart';
import 'services/settings_service.dart';
import 'services/upload_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  final settings = await SettingsService.open();
  final history = await HistoryService.open();
  final upload = UploadService(settings);

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(
        settings: settings,
        history: history,
        upload: upload,
      ),
      child: const ScanForgeApp(),
    ),
  );
}
