import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_model.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_widget.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';

/// Run 1: stationary shared abacus. Gesture playback and onComplete follow in runs 2–3.
class AbacusWarmupTrainer extends StatelessWidget {
  const AbacusWarmupTrainer({super.key, required this.params, this.onComplete});

  final Map<String, dynamic> params;
  final VoidCallback? onComplete;

  static const _totalRods = 13;

  @override
  Widget build(BuildContext context) {
    return TrainerScene(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Center(
          child: AbacusWidget(
            rods: emptyRods(_totalRods),
            totalRods: _totalRods,
          ),
        ),
      ),
    );
  }
}
