import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_widget.dart';
import 'package:larnes_mobile/trainers/shared/trainer_shell.dart';

class AbacusShowTrainer extends StatelessWidget {
  const AbacusShowTrainer({
    super.key,
    required this.params,
  });

  final Map<String, dynamic> params;

  @override
  Widget build(BuildContext context) {
    final totalRods = params['totalRods'] as int? ?? 1;
    final value = params['value'] as int? ?? 0;

    return TrainerShell(
      tone: TrainerShellTone.orange,
      child: AnimatedAbacusValue(
        value: value,
        totalRods: totalRods,
      ),
    );
  }
}
