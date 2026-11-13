import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../models/scan_record.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/scan_overlay.dart';
import 'result_screen.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with WidgetsBindingObserver {
  final MobileScannerController _controller = MobileScannerController(
    autoStart: false,
    detectionSpeed: DetectionSpeed.normal,
  );
  final ImagePicker _picker = ImagePicker();

  bool _permissionGranted = false;
  bool _checkingPermission = true;
  bool _handling = false;
  String? _lastValue;
  DateTime? _lastScanAt;
  ScanRecord? _lastContinuousRecord;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _prepareCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_permissionGranted) return;
    if (state == AppLifecycleState.resumed) {
      _controller.start();
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _controller.stop();
    }
  }

  Future<void> _prepareCamera() async {
    setState(() => _checkingPermission = true);
    final status = await Permission.camera.request();
    _permissionGranted = status.isGranted;
    setState(() => _checkingPermission = false);
    if (_permissionGranted) {
      await _controller.start();
    }
  }

  bool _shouldAccept(String value) {
    // Short hardware debounce only — app-level duplicate policy lives in AppState.
    final now = DateTime.now();
    if (_lastValue == value &&
        _lastScanAt != null &&
        now.difference(_lastScanAt!) < const Duration(milliseconds: 800)) {
      return false;
    }
    _lastValue = value;
    _lastScanAt = now;
    return true;
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handling) return;
    final barcode = capture.barcodes.isEmpty ? null : capture.barcodes.first;
    final value = barcode?.rawValue;
    if (value == null || value.isEmpty) return;
    if (!_shouldAccept(value)) return;

    final state = context.read<AppState>();
    final continuous = state.settings.continuousScan;
    final format = (barcode?.format.name ?? 'unknown');

    _handling = true;
    try {
      if (!continuous) {
        await _controller.stop();
      }

      final outcome = await state.handleScan(
        value: value,
        format: format,
        source: 'camera',
      );
      final record = outcome.record;

      if (!outcome.isDuplicate && state.settings.autoCopy) {
        await Clipboard.setData(ClipboardData(text: value));
      }

      if (!mounted) return;

      if (continuous) {
        setState(() => _lastContinuousRecord = record);
        if (outcome.isDuplicate) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Duplicate skipped — already scanned'),
              duration: Duration(milliseconds: 900),
            ),
          );
        }
      } else if (outcome.isDuplicate) {
        await _controller.start();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Duplicate skipped — already scanned')),
        );
      } else {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ResultScreen(
              recordId: record.id,
              initial: record,
            ),
          ),
        );
        if (mounted && _permissionGranted) {
          await _controller.start();
        }
      }
    } finally {
      _handling = false;
    }
  }

  Future<void> _scanFromGallery() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    final capture = await _controller.analyzeImage(file.path);
    if (!mounted) return;

    final barcode = capture?.barcodes.isNotEmpty == true
        ? capture!.barcodes.first
        : null;
    final value = barcode?.rawValue;
    if (value == null || value.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No QR or barcode found in that image')),
      );
      return;
    }

    final state = context.read<AppState>();
    final outcome = await state.handleScan(
      value: value,
      format: barcode?.format.name ?? 'unknown',
      source: 'gallery',
    );
    final record = outcome.record;

    if (!mounted) return;
    if (outcome.isDuplicate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Duplicate skipped — already scanned')),
      );
      return;
    }

    if (state.settings.autoCopy) {
      await Clipboard.setData(ClipboardData(text: value));
    }

    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ResultScreen(recordId: record.id, initial: record),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final continuous = state.settings.continuousScan;

    if (_checkingPermission) {
      return const Scaffold(
        backgroundColor: AppTheme.scannerBg,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_permissionGranted) {
      return Scaffold(
        backgroundColor: AppTheme.scannerBg,
        body: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.photo_camera_outlined,
                  color: Colors.white70, size: 56),
              const SizedBox(height: 16),
              Text(
                'Camera permission needed',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'Allow camera access to scan QR codes and barcodes.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _prepareCamera,
                child: const Text('Grant permission'),
              ),
              TextButton(
                onPressed: openAppSettings,
                child: const Text('Open settings'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.scannerBg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          ScanOverlay(continuous: continuous),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        'ScanForge',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const Spacer(),
                      _RoundIconButton(
                        icon: continuous
                            ? Icons.all_inclusive_rounded
                            : Icons.filter_1_rounded,
                        tooltip: continuous ? 'Continuous on' : 'Single scan',
                        onTap: () => state.setContinuousScan(!continuous),
                      ),
                      const SizedBox(width: 8),
                      _RoundIconButton(
                        icon: Icons.flash_on_rounded,
                        onTap: () => _controller.toggleTorch(),
                      ),
                      const SizedBox(width: 8),
                      _RoundIconButton(
                        icon: Icons.cameraswitch_rounded,
                        onTap: () => _controller.switchCamera(),
                      ),
                      const SizedBox(width: 8),
                      _RoundIconButton(
                        icon: Icons.photo_library_outlined,
                        onTap: _scanFromGallery,
                      ),
                    ],
                  ),
                  const Spacer(),
                  if (_lastContinuousRecord != null && continuous)
                    _LastScanBanner(
                      record: _lastContinuousRecord!,
                      onOpen: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ResultScreen(
                              recordId: _lastContinuousRecord!.id,
                              initial: _lastContinuousRecord,
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: Colors.black.withValues(alpha: 0.35),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}

class _LastScanBanner extends StatelessWidget {
  const _LastScanBanner({required this.record, required this.onOpen});

  final ScanRecord record;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.95),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              const Icon(Icons.qr_code_2_rounded, color: AppTheme.accent),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.formatLabel,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.ink,
                      ),
                    ),
                    Text(
                      record.value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppTheme.slate),
                    ),
                    Text(
                      'Upload: ${record.uploadStatus.name}',
                      style: TextStyle(
                        color: AppTheme.slate.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppTheme.slate),
            ],
          ),
        ),
      ),
    );
  }
}
