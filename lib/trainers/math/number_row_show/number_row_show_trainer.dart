import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/math/number_row_show/number_row_scene.dart';
import 'package:larnes_mobile/trainers/math/number_row_show/number_row_show_model.dart';
import 'package:larnes_mobile/trainers/shared/trainer_shell.dart';

class NumberRowShowTrainer extends StatelessWidget {
  const NumberRowShowTrainer({
    super.key,
    required this.params,
  });

  final Map<String, dynamic> params;

  @override
  Widget build(BuildContext context) {
    final studyDigit = normalizeStudyDigit(params['digit'] as num? ?? 0);

    return TrainerShell(
      tone: TrainerShellTone.sky,
      child: NumberRowScene(studyDigit: studyDigit),
    );
  }
}
