import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/reading/shared/passage.dart';
import 'package:larnes_mobile/trainers/reading/shared/reading_passage_play.dart';
import 'package:larnes_mobile/trainers/reading/shared/reading_passage_text.dart';
import 'package:larnes_mobile/trainers/runtime/runtime_snapshot.dart';

const readingUpsideDownInstructionText = 'Читай, текст перевёрнут';

class ReadingUpsideDownTrainer extends StatelessWidget {
  const ReadingUpsideDownTrainer({super.key, required this.params, this.onComplete});

  final Map<String, dynamic> params;
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) {
    final play =
        passagePlayFromSnapshot(
          readTrainerRuntimeSnapshot('reading-upside-down', params),
        ) ??
        passagePlayFromParams(params);

    return ReadingPassagePlay(
      instruction: readingUpsideDownInstructionText,
      trainerKey: 'reading-upside-down',
      letterCount: play.letterCount,
      letterPauseMs: play.letterPauseMs,
      onComplete: onComplete,
      resetToken: '${play.text}|${play.letterPauseMs}',
      scene: (hiddenOrder) => ReadingPassageText(
        hiddenOrder: hiddenOrder,
        units: play.units,
        upsideDown: true,
      ),
    );
  }
}
