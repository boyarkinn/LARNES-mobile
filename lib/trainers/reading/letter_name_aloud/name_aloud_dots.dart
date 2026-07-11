import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:larnes_mobile/trainers/reading/letter_name_aloud/name_aloud_sizes.dart';

const _popCurve = Cubic(0.34, 1.2, 0.64, 1);

/// Web: `platform/src/trainers/reading/letter-name-aloud/name-aloud-dots.tsx`
class NameAloudDots extends StatelessWidget {
  const NameAloudDots({
    super.key,
    required this.activeColor,
    required this.activeIndex,
    required this.completedCount,
    required this.totalCount,
  });

  final Color activeColor;
  final int activeIndex;
  final int completedCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    if (totalCount <= 1) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var index = 0; index < totalCount; index++) ...[
            if (index > 0) const SizedBox(width: 10),
            _NameAloudDot(
              color: _dotColor(index),
              size: _dotSize(index),
            ),
          ],
        ],
      ),
    );
  }

  Color _dotColor(int index) {
    final isDone = index < completedCount;
    final isCurrent = !isDone && index == activeIndex;

    if (isDone) {
      return nameAloudProgressDoneColor;
    }

    if (isCurrent) {
      return activeColor;
    }

    return nameAloudProgressPendingColor;
  }

  double _dotSize(int index) {
    final isDone = index < completedCount;
    final isCurrent = !isDone && index == activeIndex;

    return isCurrent ? 12 : 10;
  }
}

class _NameAloudDot extends StatelessWidget {
  const _NameAloudDot({
    required this.color,
    required this.size,
  });

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
