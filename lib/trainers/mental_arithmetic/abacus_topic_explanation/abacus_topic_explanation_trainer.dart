import 'dart:async';

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/audio/speech_bank.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/abacus_topic_explanation/recipes.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/audio/clip_player.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/physical_gesture_abacus.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/physical_gesture_playback.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';

/// One player per lesson instance keeps a cancelled cue from muting another trainer.
class AbacusTopicExplanationTrainer extends StatefulWidget {
  const AbacusTopicExplanationTrainer({
    super.key,
    required this.params,
    this.onComplete,
  });

  final Map<String, dynamic> params;
  final VoidCallback? onComplete;

  @override
  State<AbacusTopicExplanationTrainer> createState() =>
      _AbacusTopicExplanationTrainerState();
}

class _AbacusTopicExplanationTrainerState
    extends State<AbacusTopicExplanationTrainer> {
  final ClipPlayer _audio = ClipPlayer();
  int _cueRun = 0;

  Future<void> _playCue(String key, GestureCueSignal signal) async {
    final clip = speechAudioFile(key);
    if (clip == null || signal.cancelled) return;
    final cueRun = ++_cueRun;
    signal.onCancel(() {
      if (_cueRun == cueRun) unawaited(_audio.cancel());
    });
    if (signal.cancelled) return;
    await _audio.play([clip.path], playbackRate: 1);
  }

  @override
  void dispose() {
    _cueRun++;
    unawaited(_audio.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lessonId = widget.params['lessonId'] as String? ?? 'simple-1';
    return TrainerScene(
      child: PhysicalGestureAbacus(
        key: ValueKey(lessonId),
        plan: topicExplanationRecipe(lessonId),
        speed: switch (widget.params['speed']) {
          'slow' => PhysicalGestureSpeed.slow,
          'fast' => PhysicalGestureSpeed.fast,
          _ => PhysicalGestureSpeed.medium,
        },
        autoPlay: true,
        showHands: true,
        onComplete: widget.onComplete,
        onCue: _playCue,
      ),
    );
  }
}
