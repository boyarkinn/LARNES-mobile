import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/reading/reading_snake/model.dart';
import 'package:larnes_mobile/trainers/reading/shared/passage.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';

class ReadingSnakeScene extends StatelessWidget {
  const ReadingSnakeScene({
    super.key,
    required this.hiddenOrder,
    required this.letterCount,
    required this.units,
  });

  final int hiddenOrder;
  final int letterCount;
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
                  WidgetSpan(
                    alignment: PlaceholderAlignment.baseline,
                    baseline: TextBaseline.alphabetic,
                    child: _SnakeGrapheme(
                      head: isSnakeHead(unit, hiddenOrder, letterCount),
                      tail: isSnakeTail(unit, hiddenOrder, letterCount),
                      grapheme: unit.grapheme,
                    ),
                  ),
              ],
            ),
            textAlign: TextAlign.center,
            textDirection: TextDirection.ltr,
          ),
        ),
      ),
    );
  }
}

class _SnakeGrapheme extends StatelessWidget {
  const _SnakeGrapheme({
    required this.grapheme,
    required this.head,
    required this.tail,
  });

  final String grapheme;
  final bool head;
  final bool tail;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 8,
          child: head
              ? const DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color(0xFF166534),
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox(width: 8, height: 8),
                )
              : null,
        ),
        Text(
          grapheme,
          textDirection: TextDirection.ltr,
          style: TextStyle(
            color: const Color(0xFF20352D),
            decoration: head || tail ? TextDecoration.underline : TextDecoration.none,
            decorationColor: head ? const Color(0xFF166534) : const Color(0x73166534),
            decorationThickness: head ? 3 : 2,
            fontSize: 32,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}
