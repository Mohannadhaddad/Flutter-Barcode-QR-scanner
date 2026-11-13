import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/scan_record.dart';
import '../theme/app_theme.dart';

class ResultActions extends StatelessWidget {
  const ResultActions({
    super.key,
    required this.record,
    this.onRetryUpload,
  });

  final ScanRecord record;
  final VoidCallback? onRetryUpload;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        FilledButton.icon(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: record.value));
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copied to clipboard')),
              );
            }
          },
          icon: const Icon(Icons.copy_rounded),
          label: const Text('Copy'),
        ),
        if (record.isUrl)
          OutlinedButton.icon(
            onPressed: () async {
              final uri = Uri.parse(record.value);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            icon: const Icon(Icons.open_in_new_rounded),
            label: const Text('Open'),
          ),
        OutlinedButton.icon(
          onPressed: () => Share.share(record.value),
          icon: const Icon(Icons.ios_share_rounded),
          label: const Text('Share'),
        ),
        if (record.uploadStatus == UploadStatus.failed && onRetryUpload != null)
          OutlinedButton.icon(
            onPressed: onRetryUpload,
            style: OutlinedButton.styleFrom(foregroundColor: AppTheme.warn),
            icon: const Icon(Icons.cloud_upload_outlined),
            label: const Text('Retry upload'),
          ),
      ],
    );
  }
}
