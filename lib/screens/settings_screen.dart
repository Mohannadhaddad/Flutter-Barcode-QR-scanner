import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../services/upload_service.dart';
import '../theme/app_theme.dart';
import '../widgets/api_payload_docs.dart';
import 'about_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _urlController;
  late final TextEditingController _apiKeyController;
  bool _testing = false;

  @override
  void initState() {
    super.initState();
    final settings = context.read<AppState>().settings;
    _urlController = TextEditingController(text: settings.serverUrl);
    _apiKeyController = TextEditingController(text: settings.apiKey);
  }

  @override
  void dispose() {
    _urlController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final settings = state.settings;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text('Scanner', style: Theme.of(context).textTheme.titleLarge),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Continuous scan'),
            subtitle: const Text(
              'Keep scanning without opening each result (beep/vibrate still play)',
            ),
            value: settings.continuousScan,
            onChanged: state.setContinuousScan,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Prevent duplicates'),
            subtitle: const Text(
              'Do not save or upload the same code again within the cooldown',
            ),
            value: settings.preventDuplicates,
            onChanged: state.setPreventDuplicates,
          ),
          if (settings.preventDuplicates) ...[
            const SizedBox(height: 4),
            Text(
              'Duplicate cooldown',
              style: TextStyle(color: AppTheme.slate.withValues(alpha: 0.9)),
            ),
            const SizedBox(height: 8),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 30, label: Text('30s')),
                ButtonSegment(value: 300, label: Text('5m')),
                ButtonSegment(value: 1800, label: Text('30m')),
                ButtonSegment(value: 0, label: Text('Session')),
              ],
              selected: {
                {30, 300, 1800, 0}.contains(settings.duplicateCooldownSeconds)
                    ? settings.duplicateCooldownSeconds
                    : 300,
              },
              onSelectionChanged: (values) {
                state.setDuplicateCooldownSeconds(values.first);
              },
            ),
            const SizedBox(height: 8),
          ],
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Beep on scan'),
            subtitle: const Text('Plays for new scans in single and continuous mode'),
            value: settings.beepEnabled,
            onChanged: state.setBeepEnabled,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Vibrate on scan'),
            subtitle: const Text('Vibrates for new scans in single and continuous mode'),
            value: settings.vibrateEnabled,
            onChanged: state.setVibrateEnabled,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Auto-copy result'),
            value: settings.autoCopy,
            onChanged: state.setAutoCopy,
          ),
          const SizedBox(height: 12),
          Text('Appearance', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'system', label: Text('System')),
              ButtonSegment(value: 'light', label: Text('Light')),
              ButtonSegment(value: 'dark', label: Text('Dark')),
            ],
            selected: {settings.themeMode},
            onSelectionChanged: (values) {
              state.setThemeMode(values.first);
            },
          ),
          const SizedBox(height: 28),
          Text('Server API', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            'Scans are saved on-device first, then uploaded in the background. Use your PHP URL and API key (sent as Authorization: Bearer <key>).',
            style: TextStyle(color: AppTheme.slate.withValues(alpha: 0.9)),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Upload to server'),
            value: settings.uploadEnabled,
            onChanged: state.setUploadEnabled,
          ),
          TextField(
            controller: _urlController,
            decoration: const InputDecoration(
              labelText: 'Server URL',
              hintText: 'https://example.com/your-upload-endpoint',
            ),
            keyboardType: TextInputType.url,
            onChanged: state.setServerUrl,
            onEditingComplete: () {
              final normalized =
                  UploadService.normalizeServerUrl(_urlController.text);
              _urlController.value = TextEditingValue(
                text: normalized,
                selection: TextSelection.collapsed(offset: normalized.length),
              );
              state.setServerUrl(normalized);
              FocusScope.of(context).unfocus();
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _apiKeyController,
            decoration: const InputDecoration(
              labelText: 'API key',
              hintText: 'Your API key',
            ),
            obscureText: true,
            onChanged: state.setApiKey,
            onEditingComplete: () {
              final normalized =
                  UploadService.normalizeApiKey(_apiKeyController.text);
              _apiKeyController.value = TextEditingValue(
                text: normalized,
                selection: TextSelection.collapsed(offset: normalized.length),
              );
              state.setApiKey(normalized);
              FocusScope.of(context).unfocus();
            },
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.tonalIcon(
              onPressed: _testing
                  ? null
                  : () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final normalizedUrl =
                          UploadService.normalizeServerUrl(_urlController.text);
                      final normalizedKey =
                          UploadService.normalizeApiKey(_apiKeyController.text);
                      _urlController.text = normalizedUrl;
                      _apiKeyController.text = normalizedKey;
                      await state.setServerUrl(normalizedUrl);
                      await state.setApiKey(normalizedKey);

                      if (!mounted) return;
                      setState(() => _testing = true);
                      final result = await state.upload.testConnection();
                      if (!mounted) return;
                      setState(() => _testing = false);
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            result.isSuccess
                                ? 'Connection OK — scan saved on server'
                                : (result.message ?? 'Connection failed'),
                          ),
                          duration: const Duration(seconds: 4),
                        ),
                      );
                    },
              icon: _testing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.wifi_tethering_rounded),
              label: Text(_testing ? 'Testing…' : 'Test connection'),
            ),
          ),
          const SizedBox(height: 16),
          const ApiPayloadDocs(),
          const SizedBox(height: 28),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.info_outline_rounded, color: AppTheme.accent),
            title: const Text('About'),
            subtitle: const Text('Developer name and contact'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AboutScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}
