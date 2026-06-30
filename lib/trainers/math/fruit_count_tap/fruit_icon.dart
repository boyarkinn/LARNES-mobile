import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/math/fruit_count_tap/fruit_count_tap_model.dart';

class FruitIcon extends StatelessWidget {
  const FruitIcon({
    super.key,
    required this.fruit,
    this.size = 40,
  });

  final FruitSlug fruit;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _FruitIconPainter(fruit: fruit),
      ),
    );
  }
}

class _FruitIconPainter extends CustomPainter {
  _FruitIconPainter({required this.fruit});

  final FruitSlug fruit;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    canvas.translate(size.width / 2, size.height / 2);

    switch (fruit) {
      case 'apple':
        _paintApple(canvas, r);
      case 'banana':
        _paintBanana(canvas, r);
      case 'grape':
        _paintGrape(canvas, r);
      case 'watermelon':
        _paintWatermelon(canvas, r);
      case 'orange':
        _paintOrange(canvas, r);
      case 'pear':
        _paintPear(canvas, r);
      case 'strawberry':
        _paintStrawberry(canvas, r);
      case 'cherry':
        _paintCherry(canvas, r);
      case 'plum':
        _paintPlum(canvas, r);
      case 'peach':
        _paintPeach(canvas, r);
      default:
        _paintWatermelon(canvas, r);
    }
  }

  void _paintApple(Canvas canvas, double r) {
    canvas.drawCircle(
      Offset.zero,
      r * 0.88,
      Paint()
        ..color = const Color(0xFFFF5A5A)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset.zero,
      r * 0.88,
      Paint()
        ..color = const Color(0xFFE53935)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(r * 0.28, -r * 0.75),
        width: r * 0.6,
        height: r * 0.32,
      ),
      Paint()..color = const Color(0xFF81C784),
    );
  }

  void _paintBanana(Canvas canvas, double r) {
    final path = Path()
      ..moveTo(-r * 0.7, r * 0.2)
      ..quadraticBezierTo(r * 0.1, -r * 0.9, r * 0.75, -r * 0.15);
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFFBC02D)
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.55
        ..strokeCap = StrokeCap.round,
    );
  }

  void _paintGrape(Canvas canvas, double r) {
    const positions = [
      Offset(0, -0.35),
      Offset(-0.35, 0),
      Offset(0.35, 0),
      Offset(-0.2, 0.45),
      Offset(0.2, 0.45),
    ];
    for (final position in positions) {
      canvas.drawCircle(
        Offset(position.dx * r, position.dy * r),
        r * 0.28,
        Paint()..color = const Color(0xFF9C27B0),
      );
    }
  }

  void _paintWatermelon(Canvas canvas, double r) {
    canvas.drawCircle(
      Offset.zero,
      r * 0.9,
      Paint()
        ..color = const Color(0xFF66BB6A)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset.zero,
      r * 0.9,
      Paint()
        ..color = const Color(0xFF2E7D32)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: r * 0.9),
      0,
      math.pi,
      false,
      Paint()
        ..color = const Color(0xFFE53935)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset(-r * 0.2, r * 0.15),
      1.2,
      Paint()..color = const Color(0xFF1B5E20),
    );
    canvas.drawCircle(
      Offset(r * 0.25, -r * 0.1),
      1.2,
      Paint()..color = const Color(0xFF1B5E20),
    );
  }

  void _paintOrange(Canvas canvas, double r) {
    canvas.drawCircle(
      Offset.zero,
      r * 0.88,
      Paint()
        ..color = const Color(0xFFFF9800)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset.zero,
      r * 0.88,
      Paint()
        ..color = const Color(0xFFEF6C00)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  void _paintPear(Canvas canvas, double r) {
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, r * 0.1),
        width: r * 1.1,
        height: r * 1.5,
      ),
      Paint()..color = const Color(0xFFCDDC39),
    );
    canvas.drawCircle(
      Offset(0, -r * 0.45),
      r * 0.35,
      Paint()..color = const Color(0xFFC0CA33),
    );
  }

  void _paintStrawberry(Canvas canvas, double r) {
    final path = Path()
      ..moveTo(0, -r * 0.75)
      ..lineTo(r * 0.55, r * 0.7)
      ..lineTo(-r * 0.55, r * 0.7)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFFE53935));
    canvas.drawCircle(
      Offset(-r * 0.15, 0),
      1,
      Paint()..color = const Color(0xFFFFEB3B),
    );
    canvas.drawCircle(
      Offset(r * 0.1, r * 0.2),
      1,
      Paint()..color = const Color(0xFFFFEB3B),
    );
  }

  void _paintCherry(Canvas canvas, double r) {
    canvas.drawCircle(
      Offset(-r * 0.2, r * 0.2),
      r * 0.32,
      Paint()..color = const Color(0xFFD32F2F),
    );
    canvas.drawCircle(
      Offset(r * 0.25, r * 0.35),
      r * 0.3,
      Paint()..color = const Color(0xFFC62828),
    );
  }

  void _paintPlum(Canvas canvas, double r) {
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: r * 0.9,
        height: r * 1.2,
      ),
      Paint()..color = const Color(0xFF7B1FA2),
    );
  }

  void _paintPeach(Canvas canvas, double r) {
    canvas.drawCircle(
      Offset.zero,
      r * 0.82,
      Paint()
        ..color = const Color(0xFFFFAB91)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset.zero,
      r * 0.82,
      Paint()
        ..color = const Color(0xFFFF7043)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _FruitIconPainter oldDelegate) {
    return oldDelegate.fruit != fruit;
  }
}
