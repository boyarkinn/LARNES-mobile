import 'package:flutter/material.dart';

/// Web v2: `static-example-show/component.tsx` — `ExampleBridge`
class ExampleBridge extends StatelessWidget {
  const ExampleBridge({
    super.key,
    required this.expression,
  });

  final String expression;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: expression,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              expression,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 48,
                height: 1,
                letterSpacing: -0.5,
                color: Color(0xFF171717),
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 20),
            const SizedBox(
              width: 96,
              height: 12,
              child: CustomPaint(
                painter: _HorizontalTrainerArrowPainter(
                  color: Color(0xFF171717),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HorizontalTrainerArrowPainter extends CustomPainter {
  const _HorizontalTrainerArrowPainter({required this.color});

  final Color color;

  static const _strokeWidth = 1.75;
  static const _headHalf = 3.5;

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / 96;
    final scaleY = size.height / 12;
    final paint = Paint()
      ..color = color
      ..strokeWidth = _strokeWidth * scaleY
      ..strokeCap = StrokeCap.round;

    final centerY = 6 * scaleY;

    canvas.drawLine(
      Offset(0, centerY),
      Offset(82 * scaleX, centerY),
      paint,
    );

    final headPath = Path()
      ..moveTo((82 - _headHalf) * scaleX, (6 - _headHalf) * scaleY)
      ..lineTo(96 * scaleX, centerY)
      ..lineTo((82 - _headHalf) * scaleX, (6 + _headHalf) * scaleY)
      ..close();

    canvas.drawPath(headPath, paint..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant _HorizontalTrainerArrowPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
