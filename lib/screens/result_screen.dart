import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/scan_record.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/result_actions.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key, required this.recordId, this.initial});

  final String recordId;
  final ScanRecord? initial;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final state = context.read<AppState>();
      if (state.settings.autoCopy && widget.initial != null) {
        await Clipboard.setData(ClipboardData(text: widget.initial!.value));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final record =
        state.findById(widget.recordId) ?? widget.initial;

    if (record == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Result')),
        body: const Center(child: Text('Scan not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Scan result')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Text(
            record.formatLabel,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Scanned ${record.scannedAt.toLocal()} • ${record.source}',
            style: TextStyle(color: AppTheme.slate.withValues(alpha: 0.8)),
          ),
          const SizedBox(height: 16),
          _StatusChip(status: record.uploadStatus),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFFFFF), Color(0xFFEEF5F2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.mist),
            ),
            child: SelectableText(
              record.value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                height: 1.4,
                color: AppTheme.ink,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ResultActions(
            record: record,
            onRetryUpload: () async {
              final result = await state.retryUpload(record);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(result.message ?? result.status.name)),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final UploadStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      UploadStatus.sent => ('Sent to server', AppTheme.accent),
      UploadStatus.failed => ('Upload failed', AppTheme.warn),
      UploadStatus.pending => ('Uploading…', AppTheme.slate),
      UploadStatus.skipped => ('Not uploaded', AppTheme.slate),
    };

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
