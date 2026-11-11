import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/abacus_warmup/recipes.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/physical_gesture_abacus.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/physical_gesture_playback.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';

/// Selects one lesson recipe; all scheduling stays in the shared player.
class AbacusWarmupTrainer extends StatelessWidget {
  const AbacusWarmupTrainer({super.key, required this.params, this.onComplete});

  final Map<String, dynamic> params;
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) {
    final type = params['warmupType'] as String? ?? 'simple-9';
    return TrainerScene(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Center(
          child: PhysicalGestureAbacus(
            key: ValueKey(type),
            plan: warmupRecipe(type),
            speed: switch (params['speed']) {
              'slow' => PhysicalGestureSpeed.slow,
              'fast' => PhysicalGestureSpeed.fast,
              _ => PhysicalGestureSpeed.medium,
            },
            onComplete: onComplete,
          ),
        ),
      ),
    );
  }
}
