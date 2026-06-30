import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/shared/dot_layout.dart';

enum DotGroupSize {
  sm,
  md,
  lg,

  /// Как в `dots-digit-abacus`: 112×112 для ≤9 точек, иначе 160×160.
  auto,
}

enum DotGroupTone {
  orange,
  indigo,
}

class DotGroup extends StatelessWidget {
  const DotGroup({
    super.key,
    required this.count,
    this.size = DotGroupSize.auto,
    this.tone = DotGroupTone.orange,
  });

  final int count;
  final DotGroupSize size;
  final DotGroupTone tone;

  @override
  Widget build(BuildContext context) {
    final spec = _sizeSpec(size, count);
    final colors = _colorsForTone(tone);

    return Container(
      width: spec.frameSize,
      height: spec.frameSize,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border, width: 2),
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
          positions: getDotPositionsForValue(count),
          dotRadius: spec.dotRadius,
          dotColor: colors.dot,
        ),
      ),
    );
  }

  static _DotGroupSizeSpec _sizeSpec(DotGroupSize size, int count) {
    switch (size) {
      case DotGroupSize.sm:
        return const _DotGroupSizeSpec(frameSize: 56, dotRadius: 5);
      case DotGroupSize.md:
        return const _DotGroupSizeSpec(frameSize: 80, dotRadius: 6);
      case DotGroupSize.lg:
        return const _DotGroupSizeSpec(frameSize: 112, dotRadius: 7);
      case DotGroupSize.auto:
        if (count <= 9) {
          return _DotGroupSizeSpec(
            frameSize: 112,
            dotRadius: getDotRadius(count),
          );
        }
        return _DotGroupSizeSpec(
          frameSize: 160,
          dotRadius: getDotRadius(count),
        );
    }
  }

  static _DotGroupColors _colorsForTone(DotGroupTone tone) {
    switch (tone) {
      case DotGroupTone.orange:
        return const _DotGroupColors(
          border: Color(0xFFFED7AA),
          dot: Color(0xFFF97316),
        );
      case DotGroupTone.indigo:
        return const _DotGroupColors(
          border: Color(0xFFE2E8F0),
          dot: Color(0xFF4F46E5),
        );
    }
  }
}

class _DotGroupSizeSpec {
  const _DotGroupSizeSpec({
    required this.frameSize,
    required this.dotRadius,
  });

  final double frameSize;
  final double dotRadius;
}

class _DotGroupColors {
  const _DotGroupColors({
    required this.border,
    required this.dot,
  });

  final Color border;
  final Color dot;
}

class _DotGroupPainter extends CustomPainter {
  _DotGroupPainter({
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
  bool shouldRepaint(covariant _DotGroupPainter oldDelegate) {
    return oldDelegate.positions != positions ||
        oldDelegate.dotRadius != dotRadius ||
        oldDelegate.dotColor != dotColor;
  }
}
