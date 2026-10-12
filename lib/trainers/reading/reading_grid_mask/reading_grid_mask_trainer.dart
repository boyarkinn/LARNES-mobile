import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/reading/reading_grid_mask/model.dart';
import 'package:larnes_mobile/trainers/reading/reading_grid_mask/reading_grid_mask_scene.dart';
import 'package:larnes_mobile/trainers/reading/shared/passage.dart';
import 'package:larnes_mobile/trainers/reading/shared/reading_passage_play.dart';
import 'package:larnes_mobile/trainers/runtime/runtime_snapshot.dart';

class ReadingGridMaskTrainer extends StatelessWidget {
  const ReadingGridMaskTrainer({super.key, required this.params, this.onComplete});

  final Map<String, dynamic> params;
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) {
    final payload = readTrainerRuntimeSnapshot('reading-grid-mask', params);
    final play = passagePlayFromSnapshot(payload) ?? passagePlayFromParams(params);
    final step = readingGridStep(payload?['gridStep'] ?? params['gridStep']);

    return ReadingPassagePlay(
      instruction: readingGridMaskInstructionText,
      letterCount: play.letterCount,
      letterPauseMs: play.letterPauseMs,
      onComplete: onComplete,
      resetToken: '${play.text}|${play.letterPauseMs}|$step',
      scene: (hiddenOrder) => ReadingGridMaskScene(
        gridStepPx: readingGridStepPx(step),
        hiddenOrder: hiddenOrder,
        units: play.units,
      ),
    );
  }
}
