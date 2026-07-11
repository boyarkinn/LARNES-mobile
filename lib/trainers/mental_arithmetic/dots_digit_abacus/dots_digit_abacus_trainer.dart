import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/dots_digit_abacus/triple_scene.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';

/// Web v2: `platform/src/trainers/mental-arithmetic/dots-digit-abacus/component.tsx`
class DotsDigitAbacusTrainer extends StatelessWidget {
  const DotsDigitAbacusTrainer({
    super.key,
    required this.params,
  });

  final Map<String, dynamic> params;

  @override
  Widget build(BuildContext context) {
    final totalRods = params['totalRods'] as int? ?? 1;
    final value = params['value'] as int? ?? 0;

    return TrainerScene(
      child: TripleScene(
        totalRods: totalRods,
        value: value,
      ),
    );
  }
}
