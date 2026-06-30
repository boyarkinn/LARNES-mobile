import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/shared/dot_layout.dart';

class DotGroup extends StatelessWidget {
  const DotGroup({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final positions = getDotPositionsForValue(count);
    final dotRadius = getDotRadius(count);
    final useLargeFrame = count <= 9;
    final size = useLargeFrame ? 112.0 : 160.0;
    final width = useLargeFrame ? 112.0 : 160.0;

    return Container(
      width: width,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFED7AA), width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: CustomPaint(
        painter: _DotGroupPainter(
          positions: positions,
          dotRadius: dotRadius,
        ),
      ),
    );
  }
}

class _DotGroupPainter extends CustomPainter {
  _DotGroupPainter({
    required this.positions,
    required this.dotRadius,
  });

  final List<DotPosition> positions;
  final double dotRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFF97316);

    for (final position in positions) {
      canvas.drawCircle(
        Offset(position.x * size.width, position.y * size.height),
        dotRadius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DotGroupPainter oldDelegate) {
    return oldDelegate.positions != positions ||
        oldDelegate.dotRadius != dotRadius;
  }
}
