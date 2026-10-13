import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/reading/reading_pointer/reading_pointer_scene.dart';
import 'package:larnes_mobile/trainers/reading/shared/passage.dart';
import 'package:larnes_mobile/trainers/reading/shared/reading_passage_play.dart';
import 'package:larnes_mobile/trainers/runtime/runtime_snapshot.dart';

const readingPointerInstructionText = 'Читай, указка показывает букву';

class ReadingPointerTrainer extends StatelessWidget {
  const ReadingPointerTrainer({super.key, required this.params, this.onComplete});

  final Map<String, dynamic> params;
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) {
    final play =
        passagePlayFromSnapshot(readTrainerRuntimeSnapshot('reading-pointer', params)) ??
        passagePlayFromParams(params);

    return ReadingPassagePlay(
      instruction: readingPointerInstructionText,
      trainerKey: 'reading-pointer',
      letterCount: play.letterCount,
      letterPauseMs: play.letterPauseMs,
      onComplete: onComplete,
      resetToken: '${play.text}|${play.letterPauseMs}',
      scene: (hiddenOrder) => ReadingPointerScene(
        hiddenOrder: hiddenOrder,
        units: play.units,
      ),
    );
  }
}
