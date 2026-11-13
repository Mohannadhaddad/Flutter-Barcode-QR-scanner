import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/scan_record.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import 'result_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final records = state.filteredRecords;

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          if (state.records.isNotEmpty)
            IconButton(
              tooltip: 'Clear all',
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Clear history?'),
                    content: const Text(
                      'This permanently deletes all saved scans on this device.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  await state.clearHistory();
                }
              },
              icon: const Icon(Icons.delete_sweep_outlined),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              onChanged: state.setHistoryQuery,
              decoration: const InputDecoration(
                hintText: 'Search value or format',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          Expanded(
            child: records.isEmpty
                ? const _EmptyHistory()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: records.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final record = records[index];
                      return Dismissible(
                        key: ValueKey(record.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: AppTheme.warn.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.delete_outline,
                              color: AppTheme.warn),
                        ),
                        onDismissed: (_) => state.deleteRecord(record.id),
                        child: _HistoryTile(record: record),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.record});

  final ScanRecord record;

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  ResultScreen(recordId: record.id, initial: record),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.accentSoft.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.qr_code_rounded, color: AppTheme.ink),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${record.formatLabel} • ${record.uploadStatus.name}',
                      style: TextStyle(
                        color: AppTheme.slate.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              if (record.uploadStatus == UploadStatus.failed)
                IconButton(
                  tooltip: 'Retry upload',
                  onPressed: () async {
                    final result = await state.retryUpload(record);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(result.message ?? result.status.name),
                      ),
                    );
                  },
                  icon: const Icon(Icons.cloud_upload_outlined),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_rounded,
                size: 48, color: AppTheme.slate.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text(
              'No scans yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            const Text(
              'Successful scans will appear here for quick reopen, share, or retry upload.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
