import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/math/shop_pay/shop_pay_model.dart';

class ShopItemIcon extends StatelessWidget {
  const ShopItemIcon({
    super.key,
    required this.item,
    this.size = 72,
  });

  final ShopItemSlug item;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ShopItemIconPainter(item: item),
      ),
    );
  }
}

class _ShopItemIconPainter extends CustomPainter {
  _ShopItemIconPainter({required this.item});

  final ShopItemSlug item;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    canvas.translate(size.width / 2, size.height / 2);

    switch (item) {
      case 'candy':
        _paintCandy(canvas, r);
      case 'ice-cream':
        _paintIceCream(canvas, r);
      case 'car':
        _paintCar(canvas, r);
      case 'doll':
        _paintDoll(canvas, r);
      case 'banana':
        _paintBanana(canvas, r);
      default:
        _paintCandy(canvas, r);
    }
  }

  void _paintCandy(Canvas canvas, double r) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(0, -r * 0.05),
        width: r * 1.4,
        height: r * 1.1,
      ),
      Radius.circular(r * 0.15),
    );
    canvas.drawRRect(
      rect,
      Paint()
        ..color = const Color(0xFFFF8A80)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      rect,
      Paint()
        ..color = const Color(0xFFE53935)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    for (final dx in [-1.0, 1.0]) {
      canvas.drawLine(
        Offset(dx * r * 0.7, -r * 0.1),
        Offset(dx * r * 1.05, -r * 0.35),
        Paint()
          ..color = const Color(0xFFECEFF1)
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _paintIceCream(Canvas canvas, double r) {
    final scoop = Path()
      ..moveTo(-r * 0.45, -r * 0.15)
      ..quadraticBezierTo(0, -r * 0.95, r * 0.45, -r * 0.15)
      ..close();
    canvas.drawPath(scoop, Paint()..color = const Color(0xFFF8BBD0));
    canvas.drawPath(
      scoop,
      Paint()
        ..color = const Color(0xFFEC407A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final cone = Path()
      ..moveTo(-r * 0.45, -r * 0.15)
      ..lineTo(r * 0.45, -r * 0.15)
      ..lineTo(0, r * 0.95)
      ..close();
    canvas.drawPath(cone, Paint()..color = const Color(0xFFFFD54F));
    canvas.drawPath(
      cone,
      Paint()
        ..color = const Color(0xFFF9A825)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _paintCar(Canvas canvas, double r) {
    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(0, r * 0.175),
        width: r * 1.5,
        height: r * 0.55,
      ),
      Radius.circular(r * 0.12),
    );
    canvas.drawRRect(body, Paint()..color = const Color(0xFF42A5F5));
    canvas.drawRRect(
      body,
      Paint()
        ..color = const Color(0xFF1565C0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(0, -r * 0.275),
          width: r * 0.75,
          height: r * 0.35,
        ),
        Radius.circular(r * 0.08),
      ),
      Paint()..color = const Color(0xFF90CAF9),
    );
    for (final dx in [-0.45, 0.45]) {
      canvas.drawCircle(
        Offset(dx * r, r * 0.5),
        r * 0.18,
        Paint()..color = const Color(0xFF37474F),
      );
    }
  }

  void _paintDoll(Canvas canvas, double r) {
    canvas.drawCircle(
      Offset(0, -r * 0.35),
      r * 0.28,
      Paint()
        ..color = const Color(0xFFFFCCBC)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset(0, -r * 0.35),
      r * 0.28,
      Paint()
        ..color = const Color(0xFFFF8A65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    final dress = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(0, r * 0.325),
        width: r * 0.55,
        height: r * 0.75,
      ),
      Radius.circular(r * 0.2),
    );
    canvas.drawRRect(dress, Paint()..color = const Color(0xFFF48FB1));
    canvas.drawRRect(
      dress,
      Paint()
        ..color = const Color(0xFFEC407A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    for (final arm in [
      (Offset(-r * 0.35, 0.0), Offset(-r * 0.65, r * 0.35)),
      (Offset(r * 0.35, 0.0), Offset(r * 0.65, r * 0.35)),
    ]) {
      canvas.drawLine(
        arm.$1,
        arm.$2,
        Paint()
          ..color = const Color(0xFFFF8A65)
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _paintBanana(Canvas canvas, double r) {
    final path = Path()
      ..moveTo(-r * 0.75, r * 0.15)
      ..quadraticBezierTo(r * 0.05, -r * 0.95, r * 0.8, -r * 0.1);
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFFBC02D)
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.5
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0x59F9A825)
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.22
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _ShopItemIconPainter oldDelegate) {
    return oldDelegate.item != item;
  }
}
