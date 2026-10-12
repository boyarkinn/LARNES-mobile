import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/reading/shared/passage.dart';
import 'package:larnes_mobile/trainers/reading/shared/reading_passage_play.dart';
import 'package:larnes_mobile/trainers/reading/shared/reading_passage_text.dart';
import 'package:larnes_mobile/trainers/runtime/runtime_snapshot.dart';

const readingVanishInstructionText = 'Читай, текст будет исчезать';

class ReadingVanishTrainer extends StatelessWidget {
  const ReadingVanishTrainer({super.key, required this.params, this.onComplete});

  final Map<String, dynamic> params;
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) {
    final play =
        passagePlayFromSnapshot(readTrainerRuntimeSnapshot('reading-vanish', params)) ??
        passagePlayFromParams(params);

    return ReadingPassagePlay(
      instruction: readingVanishInstructionText,
      letterCount: play.letterCount,
      letterPauseMs: play.letterPauseMs,
      onComplete: onComplete,
      resetToken: '${play.text}|${play.letterPauseMs}',
      scene: (hiddenOrder) => ReadingPassageText(
        hiddenOrder: hiddenOrder,
        units: play.units,
      ),
    );
  }
}
