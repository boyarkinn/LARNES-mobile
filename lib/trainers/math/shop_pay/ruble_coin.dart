import 'package:flutter/material.dart';

class RubleCoin extends StatelessWidget {
  const RubleCoin({
    super.key,
    this.size = 52,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    final r = size / 2;

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RubleCoinPainter(r: r),
      ),
    );
  }
}

class _RubleCoinPainter extends CustomPainter {
  _RubleCoinPainter({required this.r});

  final double r;

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
        text: '1',
        style: TextStyle(
          color: const Color(0xFFE65100),
          fontSize: r * 0.72,
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
  bool shouldRepaint(covariant _RubleCoinPainter oldDelegate) => false;
}
