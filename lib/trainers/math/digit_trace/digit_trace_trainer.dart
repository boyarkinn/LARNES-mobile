import 'dart:async';

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/math/digit_trace/digit_trace_audio.dart';
import 'package:larnes_mobile/trainers/math/digit_trace/trace_pad.dart';
import 'package:larnes_mobile/trainers/shared/instruction/load_trainer_instruction_duration.dart';
import 'package:larnes_mobile/trainers/shared/instruction/trainer_instruction_scene.dart';
import 'package:larnes_mobile/trainers/shared/instruction/trainer_instruction_typewriter.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';
import 'package:larnes_mobile/trainers/shared/trainer_timings.dart';

enum DigitTracePhase { instruction, countdown, play }

/// Web v2: `platform/src/trainers/math/digit-trace/component.tsx`
class DigitTraceTrainer extends StatefulWidget {
  const DigitTraceTrainer({
    super.key,
    required this.params,
    this.onComplete,
  });

  final Map<String, dynamic> params;
  final VoidCallback? onComplete;

  @override
  State<DigitTraceTrainer> createState() => _DigitTraceTrainerState();
}

class _DigitTraceTrainerState extends State<DigitTraceTrainer> {
  static const _countdownLabels = ['3', '2', '1', 'СТАРТ'];
  static const _countdownStepMs = 750;
  static const _countdownColor = Color(0xFFDC2626);

  DigitTracePhase _phase = DigitTracePhase.instruction;
  String _countdownLabel = _countdownLabels.first;
  var _instructionLength = 0;
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
  void didUpdateWidget(DigitTraceTrainer oldWidget) {
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
    unawaited(cancelDigitTraceAudio());
    super.dispose();
  }

  void _startSession() {
    final runToken = Object();
    _runToken = runToken;
    _instructionTypewriter.cancel();
    _countdownTimer?.cancel();
    _completeTimer?.cancel();
    unawaited(cancelDigitTraceAudio());

    setState(() {
      _phase = DigitTracePhase.instruction;
      _instructionLength = 0;
      _countdownLabel = _countdownLabels.first;
      _completeCalled = false;
    });

    unawaited(_runInstruction(runToken));
  }

  Future<void> _runInstruction(Object runToken) async {
    final durationMs = await loadTrainerInstructionDurationMs(
      assetPath: getDigitTraceInstructionAudioAsset(),
      playbackRate: kDigitTraceInstructionPlaybackRate,
      fallbackMs: kDigitTraceInstructionDurationFallbackMs,
    );
    if (!mounted || !identical(runToken, _runToken)) {
      return;
    }

    _instructionTypewriter.start(
      text: digitTraceInstructionText,
      durationMs: durationMs,
      isCurrent: () => mounted && identical(runToken, _runToken),
      onLength: (length) {
        if (!mounted || !identical(runToken, _runToken)) {
          return;
        }
        setState(() => _instructionLength = length);
      },
    );

    await playDigitTraceInstruction();
    if (!mounted || !identical(runToken, _runToken)) {
      return;
    }

    _instructionTypewriter.cancel();
    setState(() {
      _instructionLength = digitTraceInstructionText.length;
      _phase = DigitTracePhase.countdown;
    });
    _runCountdown(runToken);
  }

  void _runCountdown(Object runToken) {
    _countdownTimer?.cancel();
    var index = 0;

    void showNext() {
      if (!mounted || !identical(runToken, _runToken)) {
        return;
      }

      if (index >= _countdownLabels.length) {
        setState(() => _phase = DigitTracePhase.play);
        return;
      }

      setState(() => _countdownLabel = _countdownLabels[index]);
      index += 1;
      _countdownTimer = Timer(
        const Duration(milliseconds: _countdownStepMs),
        showNext,
      );
    }

    showNext();
  }

  void _handlePassed(int _) {
    _scheduleComplete();
  }

  void _scheduleComplete() {
    if (_completeCalled || widget.onComplete == null) {
      return;
    }

    _completeCalled = true;
    _completeTimer = Timer(
      const Duration(milliseconds: TrainerTimings.completeAfterBurstMs),
      () {
        if (mounted) {
          widget.onComplete?.call();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final digit = widget.params['digit'] as int? ?? 0;

    return TrainerScene(
      child: switch (_phase) {
        DigitTracePhase.instruction => TrainerInstructionScene(
          length: _instructionLength,
          text: digitTraceInstructionText,
        ),
        DigitTracePhase.countdown => Center(
          child: Text(
            _countdownLabel,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: MediaQuery.sizeOf(context).shortestSide * 0.26,
              height: 1,
              color: _countdownColor,
            ),
          ),
        ),
        DigitTracePhase.play => TracePad(
          digit: digit,
          onPassed: _handlePassed,
        ),
      },
    );
  }
}
