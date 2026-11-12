import 'dart:async';

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/audio/speech_bank.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/abacus_warmup_plan.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/audio/clip_player.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/physical_gesture_trainer.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/physical_gesture_playback.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/abacus_warmup_topics.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';

/// Selects one lesson recipe; all scheduling stays in the shared player.
class AbacusWarmupTrainer extends StatelessWidget {
  const AbacusWarmupTrainer({super.key, required this.params, this.onComplete});

  final Map<String, dynamic> params;
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) {
    final type = params['warmupType'] as String? ?? 'simple-9';
    final narrated = (params['warmupNarratedTopics'] as List?)?.cast<String>();
    final withExplanations = narrated == null
        ? params['withExplanations'] != false
        : narrated.isNotEmpty;
    final topics = resolveWarmupSelection(
      type,
      params['warmupTopics'] as List?,
    );
    final selectionKey =
        ':${topics.join(",")}:${narrated?.join(",") ?? 'inherit'}';
    return TrainerScene(
      child: PhysicalGestureTrainer(
        instructionKey: 'instruction:abacus-warmup',
        key: ValueKey('$type:$withExplanations$selectionKey'),
        plan: warmupPlanForParams(
          type,
          params['warmupTopics'] as List?,
          narrated,
        ),
        narrationEnabled: withExplanations,
        tempoMultiplier: narrated == null && !withExplanations ? 2 : 1,
        speed: switch (params['speed']) {
          'slow' => PhysicalGestureSpeed.slow,
          'fast' => PhysicalGestureSpeed.fast,
          _ => PhysicalGestureSpeed.medium,
        },
        onComplete: onComplete,
        onCue: (key, signal) async {
          final clip = speechAudioFile(key);
          if (clip == null || signal.cancelled) return;
          final player = getSharedClipPlayer();
          signal.onCancel(() => unawaited(player.cancel()));
          if (signal.cancelled) return;
          await player.play([clip.path], playbackRate: 1);
        },
      ),
    );
  }
}
