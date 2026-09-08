import 'dart:async';

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/math/number_row_show/number_row_interactive_scene.dart';
import 'package:larnes_mobile/trainers/math/number_row_show/number_row_show_audio.dart';
import 'package:larnes_mobile/trainers/math/number_row_show/number_row_show_model.dart';
import 'package:larnes_mobile/trainers/shared/instruction/load_trainer_instruction_duration.dart';
import 'package:larnes_mobile/trainers/shared/instruction/trainer_instruction_scene.dart';
import 'package:larnes_mobile/trainers/shared/instruction/trainer_instruction_typewriter.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';
import 'package:larnes_mobile/trainers/shared/trainer_timings.dart';

enum NumberRowShowPhase { instruction, countdown, play }

/// Web v2: `platform/src/trainers/math/number-row-show/component.tsx`
class NumberRowShowTrainer extends StatefulWidget {
  const NumberRowShowTrainer({
    super.key,
    required this.params,
    this.onComplete,
  });

  final Map<String, dynamic> params;
  final VoidCallback? onComplete;

  @override
  State<NumberRowShowTrainer> createState() => _NumberRowShowTrainerState();
}

class _NumberRowShowTrainerState extends State<NumberRowShowTrainer> {
  static const _countdownLabels = ['3', '2', '1', 'СТАРТ'];
  static const _countdownStepMs = 750;
  static const _countdownColor = Color(0xFFDC2626);

  var _phase = NumberRowShowPhase.instruction;
  var _countdownLabel = _countdownLabels.first;
  var _instructionLength = 0;
  var _isComplete = false;
  var _completeCalled = false;
  Object _runToken = Object();

  final _instructionTypewriter = TrainerInstructionTypewriter();
  Timer? _countdownTimer;
  Timer? _completeTimer;

  @override
  void initState() {
    super.initState();
    _startSession();
  }

  @override
  void didUpdateWidget(NumberRowShowTrainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.params != widget.params) {
      _startSession();
    }
  }

  @override
  void dispose() {
    _instructionTypewriter.cancel();
    _countdownTimer?.cancel();
    _completeTimer?.cancel();
    unawaited(cancelNumberRowShowAudio());
    super.dispose();
  }

  void _startSession() {
    final runToken = Object();
    _runToken = runToken;
    _instructionTypewriter.cancel();
    _countdownTimer?.cancel();
    _completeTimer?.cancel();
    unawaited(cancelNumberRowShowAudio());

    setState(() {
      _phase = NumberRowShowPhase.instruction;
      _instructionLength = 0;
      _countdownLabel = _countdownLabels.first;
      _isComplete = false;
      _completeCalled = false;
    });

    unawaited(_runInstruction(runToken));
  }

  Future<void> _runInstruction(Object runToken) async {
    final durationMs = await loadTrainerInstructionDurationMs(
      assetPath: getNumberRowShowInstructionAudioAsset(),
      playbackRate: kNumberRowShowInstructionPlaybackRate,
      fallbackMs: kNumberRowShowInstructionDurationFallbackMs,
    );
    if (!mounted || !identical(runToken, _runToken)) {
      return;
    }

    _instructionTypewriter.start(
      text: kNumberRowShowInstructionText,
      durationMs: durationMs,
      isCurrent: () => mounted && identical(runToken, _runToken),
      onLength: (length) {
        if (!mounted || !identical(runToken, _runToken)) {
          return;
        }
        setState(() => _instructionLength = length);
      },
    );

    await playNumberRowShowInstruction();
    if (!mounted || !identical(runToken, _runToken)) {
      return;
    }

    _instructionTypewriter.cancel();
    setState(() {
      _instructionLength = kNumberRowShowInstructionText.length;
      _phase = NumberRowShowPhase.countdown;
    });
    _startCountdown(runToken);
  }

  void _startCountdown(Object runToken) {
    _countdownTimer?.cancel();
    var index = 0;

    void tick() {
      if (!mounted || !identical(runToken, _runToken)) {
        return;
      }

      if (index >= _countdownLabels.length) {
        setState(() => _phase = NumberRowShowPhase.play);
        return;
      }

      setState(() => _countdownLabel = _countdownLabels[index]);
      index += 1;
      _countdownTimer = Timer(
        const Duration(milliseconds: _countdownStepMs),
        tick,
      );
    }

    tick();
  }

  void _handleSceneComplete() {
    if (_isComplete) {
      return;
    }

    setState(() => _isComplete = true);

    _completeTimer?.cancel();
    _completeTimer = Timer(const Duration(milliseconds: TrainerTimings.completeDelayMs), () {
      if (!mounted || _completeCalled) {
        return;
      }
      _completeCalled = true;
      widget.onComplete?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    final studyDigit = normalizeStudyDigit(widget.params['digit'] as num? ?? 1);
    final stepPauseSec = normalizeStepPauseSec(widget.params['stepPauseSec']);

    return TrainerScene(
      child: switch (_phase) {
        NumberRowShowPhase.instruction => TrainerInstructionScene(
            length: _instructionLength,
            text: kNumberRowShowInstructionText,
          ),
        NumberRowShowPhase.countdown => Center(
            child: Text(
              _countdownLabel,
              style: const TextStyle(
                fontSize: 96,
                fontWeight: FontWeight.w700,
                color: _countdownColor,
                height: 1,
              ),
            ),
          ),
        NumberRowShowPhase.play => NumberRowInteractiveScene(
            studyDigit: studyDigit,
            stepPauseSec: stepPauseSec,
            disabled: _isComplete,
            onComplete: _handleSceneComplete,
          ),
      },
    );
  }
}
