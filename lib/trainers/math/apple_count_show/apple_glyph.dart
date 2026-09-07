import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/math/apple_count_show/apple_count_show_geometry.dart';

/// SVG-яблоко для drag-сцены.
class AppleGlyph extends StatelessWidget {
  const AppleGlyph({super.key, this.size = 52});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _AppleGlyphPainter(),
      ),
    );
  }
}

class _AppleGlyphPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / (AppleSceneLayout.appleRadius * 2);
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(scale);
    _drawApple(canvas);
  }

  void _drawApple(Canvas canvas) {
    const r = AppleSceneLayout.appleRadius;

    canvas.drawOval(
      Rect.fromCenter(center: Offset(0, r * 0.35), width: r * 1.7, height: r * 0.44),
      Paint()..color = const Color(0x18000000),
    );
    canvas.drawCircle(Offset.zero, r, Paint()..color = const Color(0xFFFF5A5A));
    canvas.drawCircle(
      Offset.zero,
      r,
      Paint()
        ..color = const Color(0xFFE53935)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    canvas.drawCircle(
      const Offset(-r * 0.28, -r * 0.22),
      r * 0.22,
      Paint()..color = const Color(0x55FFFFFF),
    );

    final stem = Path()
      ..moveTo(0, -r * 0.95)
      ..cubicTo(r * 0.15, -r * 1.2, r * 0.35, -r * 1.05, r * 0.2, -r * 0.75);
    canvas.drawPath(
      stem,
      Paint()
        ..color = const Color(0xFF6D4C41)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(r * 0.28, -r * 0.82),
        width: r * 0.68,
        height: r * 0.36,
      ),
      Paint()..color = const Color(0xFF81C784),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Корзина для нижней зоны drop.
class BasketGlyph extends StatelessWidget {
  const BasketGlyph({super.key, this.height = 120});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppleSceneLayout.width,
      height: height,
      child: CustomPaint(
        painter: _BasketGlyphPainter(),
      ),
    );
  }
}

class _BasketGlyphPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.height / AppleSceneLayout.height;
    canvas.scale(scale);

    final left = AppleSceneLayout.basketCenterX - AppleSceneLayout.basketHalfWidth;
    final right = AppleSceneLayout.basketCenterX + AppleSceneLayout.basketHalfWidth;
    final bottom = AppleSceneLayout.basketTopY + AppleSceneLayout.basketBodyDepth;
    const rimInset = 14.0;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(AppleSceneLayout.basketCenterX, bottom + 10),
        width: AppleSceneLayout.basketHalfWidth * 1.64,
        height: 20,
      ),
      Paint()..color = const Color(0x12000000),
    );

    final basketPath = Path()
      ..moveTo(left + rimInset, AppleSceneLayout.basketTopY)
      ..lineTo(right - rimInset, AppleSceneLayout.basketTopY)
      ..lineTo(right, bottom)
      ..quadraticBezierTo(AppleSceneLayout.basketCenterX, bottom + 20, left, bottom)
      ..close();

    canvas.drawPath(basketPath, Paint()..color = const Color(0xFFD7A86E));
    canvas.drawPath(
      basketPath,
      Paint()
        ..color = const Color(0xFFB8864E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    final handlePath = Path()
      ..moveTo(left + 22, AppleSceneLayout.basketTopY)
      ..quadraticBezierTo(
        AppleSceneLayout.basketCenterX,
        AppleSceneLayout.basketTopY - AppleSceneLayout.basketRimLift,
        right - 22,
        AppleSceneLayout.basketTopY,
      );
    canvas.drawPath(
      handlePath,
      Paint()
        ..color = const Color(0xFF8D6E43)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5
        ..strokeCap = StrokeCap.round,
    );

    for (final y in [
      AppleSceneLayout.basketTopY + 18,
      AppleSceneLayout.basketTopY + 42,
      AppleSceneLayout.basketTopY + 66,
      AppleSceneLayout.basketTopY + 90,
    ]) {
      canvas.drawLine(
        Offset(left + 28, y),
        Offset(right - 28, y),
        Paint()
          ..color = const Color(0xFFC49A6C)
          ..strokeWidth = 2.5,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
