import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/reading/letter_draw_show/draw_show_sizes.dart';

/// Web: `platform/src/trainers/reading/letter-draw-show/draw-round-dots.tsx`
class DrawRoundDots extends StatelessWidget {
  const DrawRoundDots({
    super.key,
    required this.completedRounds,
    required this.totalRounds,
  });

  final int completedRounds;
  final int totalRounds;

  @override
  Widget build(BuildContext context) {
    if (totalRounds <= 1) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var index = 0; index < totalRounds; index++) ...[
            if (index > 0) const SizedBox(width: 10),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: index < completedRounds
                    ? drawRoundDoneColor
                    : drawRoundPendingColor,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
