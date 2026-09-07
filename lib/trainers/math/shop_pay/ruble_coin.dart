import 'package:flutter/material.dart';

class RubleCoin extends StatelessWidget {
  const RubleCoin({
    super.key,
    this.size = 52,
    this.value = 1,
  });

  final double size;
  final int value;

  @override
  Widget build(BuildContext context) {
    final r = size / 2;
    final label = value.toString();
    final fontSize = label.length > 1 ? r * 0.58 : r * 0.72;

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RubleCoinPainter(
          fontSize: fontSize,
          label: label,
          r: r,
        ),
      ),
    );
  }
}

class _RubleCoinPainter extends CustomPainter {
  _RubleCoinPainter({
    required this.r,
    required this.label,
    required this.fontSize,
  });

  final double r;
  final String label;
  final double fontSize;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.translate(size.width / 2, size.height / 2);

    canvas.drawCircle(
      Offset.zero,
      r * 0.92,
      Paint()
        ..color = const Color(0xFFFFE082)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset.zero,
      r * 0.92,
      Paint()
        ..color = const Color(0xFFF9A825)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    canvas.drawCircle(
      Offset.zero,
      r * 0.72,
      Paint()
        ..color = const Color(0xFFF57F17)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: const Color(0xFFE65100),
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, -textPainter.height / 2 + 1),
    );
  }

  @override
  bool shouldRepaint(covariant _RubleCoinPainter oldDelegate) {
    return oldDelegate.label != label || oldDelegate.fontSize != fontSize;
  }
}
