import 'dart:async';

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/audio/speech_bank.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/abacus_topic_explanation/example_profile.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/abacus_topic_explanation/run_recipe.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/audio/clip_player.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/physical_gesture_trainer.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/physical_gesture_playback.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/physical_gesture_plan.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/topic_example_generation.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/types.dart';
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
  static final Map<String, String> _previousExamples = {};
  late String _lessonId;
  late PhysicalGesturePlan _plan;
  late Chain _example;
  late String _audioLocale;

  @override
  void initState() {
    super.initState();
    _createRun();
  }

  void _createRun() {
    _lessonId = widget.params['lessonId'] as String? ?? 'simple-1';
    _example = generateTopicExample(
      topicExplanationExampleProfile(_lessonId),
      previousSignature: _previousExamples[_lessonId],
    );
    _previousExamples[_lessonId] = chainExampleSignature(_example.steps);
    _buildPlan();
  }

  void _buildPlan() {
    _audioLocale =
        speechAudioFile('explanation:abacus-topic:answer')?.locale ?? 'ru-RU';
    _plan = topicExplanationRunRecipe(_lessonId, _example, _audioLocale);
  }

  @override
  void didUpdateWidget(AbacusTopicExplanationTrainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((widget.params['lessonId'] as String? ?? 'simple-1') != _lessonId) {
      _createRun();
    } else if ((speechAudioFile('explanation:abacus-topic:answer')?.locale ??
            'ru-RU') !=
        _audioLocale) {
      _buildPlan();
    }
  }

  Future<void> _playCue(String key, GestureCueSignal signal) async {
    final clips = physicalGestureCueKeys(
      _plan,
      key,
    ).map(speechAudioFile).toList();
    if (clips.any((clip) => clip == null) || signal.cancelled) return;
    final cueRun = ++_cueRun;
    signal.onCancel(() {
      if (_cueRun == cueRun) unawaited(_audio.cancel());
    });
    if (signal.cancelled) return;
    await _audio.play(
      clips.map((clip) => clip!.path).toList(),
      playbackRate: 1,
    );
  }

  @override
  void dispose() {
    _cueRun++;
    unawaited(_audio.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TrainerScene(
      child: PhysicalGestureTrainer(
        instructionKey: 'instruction:abacus-topic-explanation',
        key: ValueKey(_lessonId),
        plan: _plan,
        speed: switch (widget.params['speed']) {
          'slow' => PhysicalGestureSpeed.slow,
          'fast' => PhysicalGestureSpeed.fast,
          _ => PhysicalGestureSpeed.medium,
        },
        onComplete: widget.onComplete,
        onCue: _playCue,
      ),
    );
  }
}
