import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/runtime/runtime_snapshot.dart';
import 'package:larnes_mobile/trainers/runtime/trainer_result_scope.dart';
import 'package:larnes_mobile/trainers/reading/shared/text_passage_play.dart';
import 'model.dart';

const readingShutterInstructionText = 'Читай, часть текста закрыта';

class ReadingShutterTrainer extends StatelessWidget {
  const ReadingShutterTrainer({
    super.key,
    required this.params,
    this.onComplete,
  });
  final Map<String, dynamic> params;
  final VoidCallback? onComplete;
  @override
  Widget build(BuildContext context) {
    final plan =
        readingShutterPlanFromSnapshot(
          readTrainerRuntimeSnapshot('reading-shutter', params),
        ) ??
        readingShutterPlanFromParams(params);
    return TextPassagePlay(
      key: ValueKey((
        TrainerResultScope.maybeOf(context)?.storageKey,
        plan.text,
        plan.letterPauseMs,
        plan.disappearance,
        plan.visibleHalf,
      )),
      trainerKey: 'reading-shutter',
      plan: plan,
      instruction: readingShutterInstructionText,
      onComplete: onComplete,
    );
  }
}
