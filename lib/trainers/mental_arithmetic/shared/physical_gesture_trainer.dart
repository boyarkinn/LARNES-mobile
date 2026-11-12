import 'dart:async';

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/audio/catalog_playback_failure.dart';
import 'package:larnes_mobile/trainers/audio/speech_bank.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/audio/clip_player.dart';
import 'package:larnes_mobile/trainers/shared/instruction/trainer_instruction_scene.dart';
import 'package:larnes_mobile/trainers/shared/instruction/trainer_instruction_typewriter.dart';

import 'physical_gesture_abacus.dart';
import 'physical_gesture_plan.dart';
import 'physical_gesture_playback.dart';

enum PhysicalGestureIntroductionMode { screen, inline }

/// Both trainers reuse their first published cue as the standard introduction.
/// The original plan stays intact so its movement/checkpoint indices are stable.
class PhysicalGestureTrainer extends StatefulWidget {
  const PhysicalGestureTrainer({
    super.key,
    required this.plan,
    required this.speed,
    required this.onCue,
    required this.instructionKey,
    this.onComplete,
    this.narrationEnabled = true,
    this.tempoMultiplier = 1,
    this.introductionMode = PhysicalGestureIntroductionMode.screen,
    this.autoPlay = true,
  });

  final PhysicalGesturePlan plan;
  final PhysicalGestureSpeed speed;

  /// Controls action cues only; the standard launch instruction always plays.
  final bool narrationEnabled;
  final double tempoMultiplier;
  final PhysicalGestureIntroductionMode introductionMode;
  final bool autoPlay;
  final String instructionKey;
  final Future<void> Function(String, GestureCueSignal) onCue;
  final VoidCallback? onComplete;

  @override
  State<PhysicalGestureTrainer> createState() => _PhysicalGestureTrainerState();
}

class _PhysicalGestureTrainerState extends State<PhysicalGestureTrainer> {
  final _audio = ClipPlayer();
  final _typewriter = TrainerInstructionTypewriter();
  bool _introduced = false;
  int _length = 0;
  String _text = '';
  String? _introductionKey;
  Object _run = Object();

  @override
  void initState() {
    super.initState();
    _startIntroduction();
  }

  @override
  void didUpdateWidget(PhysicalGestureTrainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (physicalGestureIntroductionKey(widget.plan) != _introductionKey ||
        oldWidget.introductionMode != widget.introductionMode) {
      _startIntroduction();
    }
  }

  void _startIntroduction() {
    final run = _run = Object();
    _typewriter.cancel();
    unawaited(_audio.cancel());
    _introductionKey = physicalGestureIntroductionKey(widget.plan);
    if (widget.introductionMode == PhysicalGestureIntroductionMode.inline) {
      _introduced = true;
      _length = 0;
      _text = '';
      return;
    }
    final clip =
        speechAudioFile(widget.instructionKey) ??
        (_introductionKey == null ? null : speechAudioFile(_introductionKey!));
    _introduced = clip == null;
    _length = 0;
    _text = clip?.text ?? '';
    // Unpublished legacy launches retain their silent fallback.
    if (clip == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !identical(run, _run)) return;
      unawaited(_playIntroduction(clip, run));
    });
  }

  Future<void> _playIntroduction(SpeechAudioFile clip, Object run) async {
    bool isCurrent() => mounted && identical(run, _run);
    _typewriter.start(
      text: _text,
      speechKey: widget.instructionKey,
      durationMs: clip.durationMs > 0 ? clip.durationMs : 1200,
      isCurrent: isCurrent,
      onLength: (length) {
        if (isCurrent()) setState(() => _length = length);
      },
    );
    final failures = catalogPlaybackFailures.value;
    await _audio.play([clip.path], playbackRate: 1);
    if (!isCurrent() || catalogPlaybackFailures.value != failures) return;
    _typewriter.cancel();
    setState(() => _introduced = true);
  }

  @override
  void dispose() {
    _run = Object();
    _typewriter.cancel();
    unawaited(_audio.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      Offstage(
        offstage: !_introduced,
        child: PhysicalGestureAbacus(
          plan: widget.plan,
          speed: widget.speed,
          tempoMultiplier: widget.tempoMultiplier,
          autoPlay: _introduced && widget.autoPlay,
          showHands: true,
          onComplete: widget.onComplete,
          onCue: widget.narrationEnabled
              ? (key, signal) async {
                  if (widget.introductionMode ==
                          PhysicalGestureIntroductionMode.screen &&
                      key == _introductionKey) {
                    return;
                  }
                  await widget.onCue(key, signal);
                }
              : null,
        ),
      ),
      if (!_introduced)
        TrainerInstructionScene(
          length: _length,
          text: _text,
          speechKey: widget.instructionKey,
        ),
    ],
  );
}
