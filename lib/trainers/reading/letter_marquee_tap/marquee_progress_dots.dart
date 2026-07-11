import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/reading/letter_marquee_tap/marquee_sizes.dart';

/// Web: `platform/src/trainers/reading/letter-marquee-tap/marquee-progress-dots.tsx`
class MarqueeProgressDots extends StatelessWidget {
  const MarqueeProgressDots({
    super.key,
    required this.caughtCount,
    required this.targetCount,
  });

  final int caughtCount;
  final int targetCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var index = 0; index < targetCount; index++) ...[
            if (index > 0) const SizedBox(width: 10),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: Color(
                  index < caughtCount
                      ? marqueeProgressDoneColor
                      : marqueeRailColor,
                ),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
