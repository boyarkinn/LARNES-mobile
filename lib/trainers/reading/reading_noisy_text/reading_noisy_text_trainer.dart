import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/reading/reading_noisy_text/model.dart';
import 'package:larnes_mobile/trainers/reading/reading_noisy_text/reading_noisy_text_scene.dart';
import 'package:larnes_mobile/trainers/reading/shared/reading_passage_play.dart';
import 'package:larnes_mobile/trainers/runtime/runtime_snapshot.dart';

const readingNoisyTextInstructionText = 'Читай, текст с помехами';

class ReadingNoisyTextTrainer extends StatelessWidget {
  const ReadingNoisyTextTrainer({super.key, required this.params, this.onComplete});

  final Map<String, dynamic> params;
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) {
    final plan =
        readingNoisyTextPlanFromSnapshot(
          readTrainerRuntimeSnapshot('reading-noisy-text', params),
        ) ??
        readingNoisyTextPlanFromParams(params);

    return ReadingPassagePlay(
      instruction: readingNoisyTextInstructionText,
      trainerKey: 'reading-noisy-text',
      letterCount: plan.letterCount,
      letterPauseMs: plan.letterPauseMs,
      onComplete: onComplete,
      resetToken: '${plan.text}|${plan.letterPauseMs}|${plan.noise}',
      scene: (hiddenOrder) => ReadingNoisyTextScene(hiddenOrder: hiddenOrder, plan: plan),
    );
  }
}
