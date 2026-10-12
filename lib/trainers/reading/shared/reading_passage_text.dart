import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/reading/shared/passage.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';

class ReadingPassageText extends StatelessWidget {
  const ReadingPassageText({
    super.key,
    required this.hiddenOrder,
    required this.units,
    this.upsideDown = false,
  });

  final int hiddenOrder;
  final List<VanishUnit> units;
  final bool upsideDown;

  @override
  Widget build(BuildContext context) {
    final paragraph = Text.rich(
      TextSpan(
        children: [
          for (final unit in units)
            TextSpan(
              text: unit.grapheme,
              style: TextStyle(
                color: hiddenOrder >= unit.order
                    ? const Color(0x0020352D)
                    : const Color(0xFF20352D),
              ),
            ),
        ],
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      style: const TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        height: 1.25,
      ),
    );

    return TrainerScene(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Center(
          child: upsideDown
              ? Transform.rotate(angle: math.pi, child: paragraph)
              : paragraph,
        ),
      ),
    );
  }
}
