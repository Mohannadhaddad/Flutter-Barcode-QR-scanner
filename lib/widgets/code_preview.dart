import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../theme/app_theme.dart';

class CodePreview extends StatelessWidget {
  const CodePreview({
    super.key,
    required this.value,
    required this.isQr,
    this.barcodeType,
  });

  final String value;
  final bool isQr;
  final Barcode? barcodeType;

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty) {
      return Container(
        height: 220,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.mist),
        ),
        child: const Text('Enter content to preview'),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.mist),
      ),
      child: isQr
          ? QrImageView(
              data: value,
              version: QrVersions.auto,
              size: 220,
              backgroundColor: Colors.white,
            )
          : BarcodeWidget(
              barcode: barcodeType ?? Barcode.code128(),
              data: value,
              width: double.infinity,
              height: 120,
              drawText: true,
              errorBuilder: (context, error) => Text(
                'Invalid data for this barcode type\n$error',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.warn),
              ),
            ),
    );
  }
}
