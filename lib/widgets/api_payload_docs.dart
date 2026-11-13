import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/api_contract.dart';
import '../theme/app_theme.dart';

class ApiPayloadDocs extends StatelessWidget {
  const ApiPayloadDocs({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.ink,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Request format',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '${ApiContract.method}  •  ${ApiContract.contentType}',
            style: const TextStyle(color: AppTheme.accentSoft),
          ),
          const SizedBox(height: 4),
          const Text(
            ApiContract.authHeader,
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 14),
          ...ApiContract.fields.map(
            (field) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 88,
                    child: Text(
                      field.name,
                      style: const TextStyle(
                        color: AppTheme.accentSoft,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${field.type} — ${field.description}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(12),
            ),
            child: SelectableText(
              ApiContract.sampleJson,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'monospace',
                fontSize: 12.5,
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () async {
                await Clipboard.setData(
                  const ClipboardData(text: ApiContract.sampleJson),
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('JSON sample copied')),
                  );
                }
              },
              icon: const Icon(Icons.copy_rounded, color: AppTheme.accentSoft),
              label: const Text(
                'Copy JSON sample',
                style: TextStyle(color: AppTheme.accentSoft),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
