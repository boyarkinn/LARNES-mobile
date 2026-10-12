import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/reading/reading_pointer/model.dart';
import 'package:larnes_mobile/trainers/reading/shared/passage.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';

class ReadingPointerScene extends StatelessWidget {
  const ReadingPointerScene({
    super.key,
    required this.hiddenOrder,
    required this.units,
  });

  final int hiddenOrder;
  final List<VanishUnit> units;

  @override
  Widget build(BuildContext context) {
    return TrainerScene(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Center(
          child: Text.rich(
            TextSpan(
              children: [
                for (final unit in units)
                  TextSpan(
                    text: unit.grapheme,
                    style: TextStyle(
                      color: hiddenOrder >= unit.order
                          ? const Color(0x0020352D)
                          : const Color(0xFF20352D),
                      decoration: isPointerLetter(unit, hiddenOrder)
                          ? TextDecoration.underline
                          : TextDecoration.none,
                      decorationColor: const Color(0xFF0369A1),
                      decorationThickness: 3,
                    ),
                  ),
              ],
            ),
            textAlign: TextAlign.center,
            textDirection: TextDirection.ltr,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ),
      ),
    );
  }
}
