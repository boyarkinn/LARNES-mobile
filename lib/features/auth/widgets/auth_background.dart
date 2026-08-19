import 'package:flutter/material.dart';
import 'package:larnes_mobile/features/auth/theme/auth_theme.dart';

class AuthBackground extends StatelessWidget {
  const AuthBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(-0.92, -0.94),
          radius: 0.55,
          colors: [Color(0x14345BFF), Colors.transparent],
          stops: [0, 0.66],
        ),
      ),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.94, 0.98),
            radius: 0.45,
            colors: [Color(0x12FF8A52), Colors.transparent],
            stops: [0, 0.68],
          ),
        ),
        child: ColoredBox(
          color: AuthColors.bg,
          child: CustomPaint(
            painter: const _AuthRuledLinesPainter(),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _AuthRuledLinesPainter extends CustomPainter {
  const _AuthRuledLinesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x09345BFF)
      ..strokeWidth = 1;

    for (
      var y = AuthMetrics.ruledLineStep;
      y < size.height;
      y += AuthMetrics.ruledLineStep
    ) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
