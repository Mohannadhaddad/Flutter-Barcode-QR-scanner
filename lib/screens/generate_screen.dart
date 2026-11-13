import 'dart:io';
import 'dart:ui' as ui;

import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../theme/app_theme.dart';
import '../widgets/code_preview.dart';

class GenerateScreen extends StatefulWidget {
  const GenerateScreen({super.key});

  @override
  State<GenerateScreen> createState() => _GenerateScreenState();
}

class _GenerateScreenState extends State<GenerateScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _qrController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _previewKey = GlobalKey();
  int _barcodeIndex = 0;

  final _barcodeOptions = <(String, Barcode)>[
    ('Code 128', Barcode.code128()),
    ('EAN-13', Barcode.ean13()),
    ('EAN-8', Barcode.ean8()),
    ('UPC-A', Barcode.upcA()),
    ('Code 39', Barcode.code39()),
    ('Codabar', Barcode.codabar()),
  ];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabs.dispose();
    _qrController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  String get _activeValue =>
      _tabs.index == 0 ? _qrController.text : _barcodeController.text;

  Future<File?> _capturePng() async {
    final boundary =
        _previewKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 3);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) return null;
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/scanforge_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await file.writeAsBytes(bytes.buffer.asUint8List());
    return file;
  }

  Future<void> _share() async {
    if (_activeValue.trim().isEmpty) return;
    final file = await _capturePng();
    if (file == null) return;
    await Share.shareXFiles([XFile(file.path)], text: _activeValue);
  }

  Future<void> _save() async {
    if (_activeValue.trim().isEmpty) return;
    final file = await _capturePng();
    if (file == null) return;
    try {
      final hasAccess = await Gal.hasAccess(toAlbum: true);
      if (!hasAccess) {
        await Gal.requestAccess(toAlbum: true);
      }
      await Gal.putImage(file.path, album: 'ScanForge');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved to gallery')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isQr = _tabs.index == 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate'),
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppTheme.accent,
          unselectedLabelColor: AppTheme.slate,
          indicatorColor: AppTheme.accent,
          tabs: const [
            Tab(text: 'QR code'),
            Tab(text: 'Barcode'),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          if (isQr)
            TextField(
              controller: _qrController,
              minLines: 2,
              maxLines: 4,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Text or URL',
                hintText: 'https://example.com',
              ),
            )
          else ...[
            DropdownButtonFormField<int>(
              key: ValueKey(_barcodeIndex),
              initialValue: _barcodeIndex,
              decoration: const InputDecoration(labelText: 'Barcode type'),
              items: [
                for (var i = 0; i < _barcodeOptions.length; i++)
                  DropdownMenuItem(
                    value: i,
                    child: Text(_barcodeOptions[i].$1),
                  ),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => _barcodeIndex = value);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _barcodeController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Barcode data',
                hintText: 'Enter valid data for the selected type',
              ),
            ),
          ],
          const SizedBox(height: 20),
          RepaintBoundary(
            key: _previewKey,
            child: CodePreview(
              value: _activeValue,
              isQr: isQr,
              barcodeType: _barcodeOptions[_barcodeIndex].$2,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _activeValue.trim().isEmpty ? null : _share,
                  icon: const Icon(Icons.ios_share_rounded),
                  label: const Text('Share'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _activeValue.trim().isEmpty ? null : _save,
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Save'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
