import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class ScanOverlay extends StatelessWidget {
  const ScanOverlay({super.key, this.continuous = false});

  final bool continuous;

  /// Cutout rectangle matching the visual scan frame for [size].
  static Rect cutOutFor(Size size) {
    final cutOut = Size(
      size.width * 0.72,
      size.width * 0.72,
    );
    final left = (size.width - cutOut.width) / 2;
    final top = (size.height - cutOut.height) / 2.4;
    return Rect.fromLTWH(left, top, cutOut.width, cutOut.height);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final cutOut = cutOutFor(size);
        final left = cutOut.left;
        final top = cutOut.top;

        return Stack(
          children: [
            CustomPaint(
              size: size,
              painter: _OverlayPainter(cutOut: cutOut),
            ),
            Positioned(
              left: left,
              top: top,
              width: cutOut.width,
              height: cutOut.height,
              child: CustomPaint(painter: _CornerPainter()),
            ),
            Positioned(
              left: 24,
              right: 24,
              top: top + cutOut.height + 28,
              child: Text(
                continuous
                    ? 'Continuous mode — keep codes in the frame'
                    : 'Align a QR or barcode inside the frame',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _OverlayPainter extends CustomPainter {
  _OverlayPainter({required this.cutOut});

  final Rect cutOut;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.55);
    final path = Path()
      ..addRect(Offset.zero & size)
      ..addRRect(RRect.fromRectAndRadius(cutOut, const Radius.circular(18)))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _OverlayPainter oldDelegate) =>
      oldDelegate.cutOut != cutOut;
}

class _CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.accentSoft
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const length = 28.0;
    final rect = Offset.zero & size;

    void corner(Offset origin, Offset a, Offset b) {
      canvas.drawLine(origin, origin + a, paint);
      canvas.drawLine(origin, origin + b, paint);
    }

    corner(rect.topLeft, const Offset(length, 0), const Offset(0, length));
    corner(rect.topRight, const Offset(-length, 0), const Offset(0, length));
    corner(rect.bottomLeft, const Offset(length, 0), const Offset(0, -length));
    corner(
      rect.bottomRight,
      const Offset(-length, 0),
      const Offset(0, -length),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
