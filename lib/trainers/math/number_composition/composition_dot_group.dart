import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/math/number_composition/composition_sizes.dart';
import 'package:larnes_mobile/trainers/shared/dot_layout.dart';

enum CompositionDotVariant { equation, choice }

/// Web: `number-composition/dot-group.tsx`
class CompositionDotGroup extends StatelessWidget {
  const CompositionDotGroup({
    super.key,
    required this.count,
    this.dotColor = compositionDotColor,
    this.variant = CompositionDotVariant.equation,
    this.frameSize,
  });

  final int count;
  final Color dotColor;
  final CompositionDotVariant variant;
  final double? frameSize;

  @override
  Widget build(BuildContext context) {
    final size = frameSize ??
        (variant == CompositionDotVariant.choice ? 80.0 : 112.0);
    final dotRadius =
        variant == CompositionDotVariant.choice ? 5.5 : 7.0;

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CompositionDotPainter(
          positions: getDotPositionsForValue(count),
          dotRadius: dotRadius,
          dotColor: dotColor,
        ),
      ),
    );
  }
}

class _CompositionDotPainter extends CustomPainter {
  _CompositionDotPainter({
    required this.positions,
    required this.dotRadius,
    required this.dotColor,
  });

  final List<DotPosition> positions;
  final double dotRadius;
  final Color dotColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = dotColor;

    for (final position in positions) {
      canvas.drawCircle(
        Offset(position.x * size.width, position.y * size.height),
        dotRadius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CompositionDotPainter oldDelegate) {
    return oldDelegate.positions != positions ||
        oldDelegate.dotRadius != dotRadius ||
        oldDelegate.dotColor != dotColor;
  }
}
