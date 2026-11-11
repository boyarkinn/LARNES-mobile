import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/physical_gesture_abacus.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/physical_gesture_plan.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/physical_gesture_playback.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_model.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';

/// Five lesson recipes arrive in run 3; the shared player is already wired.
class AbacusWarmupTrainer extends StatelessWidget {
  const AbacusWarmupTrainer({super.key, required this.params, this.onComplete});

  final Map<String, dynamic> params;
  final VoidCallback? onComplete;

  static const _totalRods = 13;
  static final _unconfiguredPlan = PhysicalGesturePlan(
    initialRods: emptyRods(_totalRods),
    steps: const [],
  );

  @override
  Widget build(BuildContext context) {
    return TrainerScene(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Center(
          child: PhysicalGestureAbacus(
            plan: _unconfiguredPlan,
            speed: switch (params['speed']) {
              'slow' => PhysicalGestureSpeed.slow,
              'fast' => PhysicalGestureSpeed.fast,
              _ => PhysicalGestureSpeed.medium,
            },
            autoPlay: false,
            onComplete: onComplete,
          ),
        ),
      ),
    );
  }
}
