import 'dart:async';

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/audio/speech_bank.dart';
import 'package:larnes_mobile/trainers/audio/number_bank.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/audio/clip_player.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/types.dart';
import 'physical_chain_example.dart';
import 'physical_gesture_plan.dart';
import 'physical_gesture_playback.dart';
import 'physical_gesture_trainer.dart';

/// Reusable content only: the caller owns the selected chain and review/retry stages.
class PhysicalChainExample extends StatefulWidget {
  const PhysicalChainExample({
    super.key,
    required this.chain,
    this.locale,
    this.stepSec = 3,
    this.stateKey = 'physical-chain-example',
    this.onComplete,
  });
  final Chain chain;
  final String? locale;
  final double stepSec;
  final String stateKey;
  final VoidCallback? onComplete;

  @override
  State<PhysicalChainExample> createState() => _PhysicalChainExampleState();
}

class _PhysicalChainExampleState extends State<PhysicalChainExample> {
  final ClipPlayer _audio = ClipPlayer();
  late PhysicalGesturePlan _plan;
  late String _audioLocale;
  int _cueRun = 0;

  @override
  void initState() {
    super.initState();
    _buildPlan();
  }

  void _buildPlan() {
    _audioLocale = widget.locale ?? numberAudioLocale;
    _plan = physicalChainExamplePlan(
      widget.chain,
      stepSec: widget.stepSec,
      locale: _audioLocale,
    );
  }

  @override
  void didUpdateWidget(PhysicalChainExample oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.chain != oldWidget.chain ||
        widget.stepSec != oldWidget.stepSec ||
        (widget.locale ?? numberAudioLocale) != _audioLocale) {
      _buildPlan();
    }
  }

  Future<void> _waitForCancellation(GestureCueSignal signal) {
    final done = Completer<void>();
    signal.onCancel(() {
      if (!done.isCompleted) done.complete();
    });
    return done.future;
  }

  Future<void> _playCue(String key, GestureCueSignal signal) async {
    if (signal.cancelled) return;
    final clips = physicalGestureCueKeys(
      _plan,
      key,
    ).map(speechAudioFile).toList();
    if (clips.any(
      (clip) =>
          clip == null || clip.path.isEmpty || clip.locale != _audioLocale,
    )) {
      await _waitForCancellation(signal);
      return;
    }
    final cueRun = ++_cueRun;
    signal.onCancel(() {
      if (_cueRun == cueRun) unawaited(_audio.cancel());
    });
    if (signal.cancelled) return;
    await _audio.play(
      clips.map((clip) => clip!.path).toList(),
      playbackRate: 1,
    );
    if (!signal.cancelled && !_audio.lastPlaybackSucceeded) {
      await _waitForCancellation(signal);
    }
  }

  @override
  void dispose() {
    _cueRun++;
    unawaited(_audio.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ready = physicalGestureAudioKeys(_plan).every((key) {
      final clip = speechAudioFile(key);
      return clip != null &&
          clip.path.isNotEmpty &&
          clip.locale == _audioLocale;
    });
    return PhysicalGestureTrainer(
      key: ValueKey(widget.stateKey),
      plan: _plan,
      speed: PhysicalGestureSpeed.medium,
      instructionKey: _plan.steps.first.audioKey!,
      introductionMode: PhysicalGestureIntroductionMode.inline,
      autoPlay: ready,
      onCue: _playCue,
      onComplete: widget.onComplete,
    );
  }
}
