import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/reading/shared/passage.dart';
import 'package:larnes_mobile/trainers/reading/shared/text_passage_model.dart';
import 'package:larnes_mobile/trainers/reading/shared/text_passage_play.dart';
import 'package:larnes_mobile/trainers/runtime/runtime_snapshot.dart';
import 'package:larnes_mobile/trainers/runtime/trainer_result_scope.dart';

const readingUpsideDownInstructionText = 'Читай, текст перевёрнут';

class ReadingUpsideDownTrainer extends StatelessWidget {
  const ReadingUpsideDownTrainer({
    super.key,
    required this.params,
    this.onComplete,
  });
  final Map<String, dynamic> params;
  final VoidCallback? onComplete;
  @override
  Widget build(BuildContext context) {
    final frozen = readTrainerRuntimeSnapshot('reading-upside-down', params);
    final plan = TextPassagePlan(
      text: frozen?['text']?.toString() ?? resolvePassageText(params),
      letterPauseMs:
          (int.tryParse(
                    '${frozen?['letterPauseMs'] ?? params['letterPauseMs'] ?? 180}',
                  ) ??
                  180)
              .clamp(80, 800),
      disappearance:
          (frozen?['disappearance'] ??
              params['disappearance'] ??
              (frozen == null ? 'off' : 'on')) ==
          'on',
    );
    return TextPassagePlay(
      key: ValueKey((
        TrainerResultScope.maybeOf(context)?.storageKey,
        plan.text,
        plan.letterPauseMs,
        plan.disappearance,
      )),
      trainerKey: 'reading-upside-down',
      plan: plan,
      upsideDown: true,
      instruction: readingUpsideDownInstructionText,
      onComplete: onComplete,
    );
  }
}
