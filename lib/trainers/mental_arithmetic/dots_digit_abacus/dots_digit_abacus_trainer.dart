import 'dart:async';

import 'package:flutter/material.dart';

import 'package:larnes_mobile/trainers/mental_arithmetic/dots_digit_abacus/dots_digit_abacus_audio.dart';

import 'package:larnes_mobile/trainers/mental_arithmetic/dots_digit_abacus/dots_digit_abacus_model.dart';

import 'package:larnes_mobile/trainers/mental_arithmetic/dots_digit_abacus/dots_digit_abacus_sizes.dart';

import 'package:larnes_mobile/trainers/mental_arithmetic/dots_digit_abacus/match_task_board.dart';

import 'package:larnes_mobile/trainers/mental_arithmetic/dots_digit_abacus/match_task_model.dart';

import 'package:larnes_mobile/trainers/mental_arithmetic/dots_digit_abacus/triple_scene.dart';

import 'package:larnes_mobile/trainers/mental_arithmetic/topic_chain_flash/answer_fireworks.dart';

import 'package:larnes_mobile/trainers/shared/instruction/load_trainer_instruction_duration.dart';

import 'package:larnes_mobile/trainers/shared/instruction/trainer_instruction_scene.dart';

import 'package:larnes_mobile/trainers/shared/instruction/trainer_instruction_typewriter.dart';

import 'package:larnes_mobile/trainers/shared/seeded_rng.dart';

import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';

import 'package:larnes_mobile/trainers/shared/trainer_timings.dart';

enum DotsDigitAbacusPhase {
  instruction,

  countdown,

  explain,

  taskInstruction,

  taskCountdown,

  match,
}

enum _CountdownTarget { explain, match }

/// Web: `platform/src/trainers/mental-arithmetic/dots-digit-abacus/component.tsx`

class DotsDigitAbacusTrainer extends StatefulWidget {
  const DotsDigitAbacusTrainer({
    super.key,

    required this.params,

    this.onComplete,
  });

  final Map<String, dynamic> params;

  final VoidCallback? onComplete;

  @override
  State<DotsDigitAbacusTrainer> createState() => _DotsDigitAbacusTrainerState();
}

class _DotsDigitAbacusTrainerState extends State<DotsDigitAbacusTrainer> {
  static const _countdownLabels = ['3', '2', '1', 'СТАРТ'];

  static const _countdownStepMs = 750;

  static const _countdownColor = Color(0xFFEA580C);

  var _phase = DotsDigitAbacusPhase.instruction;

  var _countdownTarget = _CountdownTarget.explain;

  var _countdownLabel = _countdownLabels.first;

  var _instructionLength = 0;

  var _taskInstructionLength = 0;

  var _completeCalled = false;

  var _matchCompleteCalled = false;

  var _matchDisabled = false;

  var _fireworksKey = 0;

  var _visibility = const TripleSceneVisibility();

  final _connections = <MatchTaskConnection>[];

  Object _runToken = Object();

  final _instructionTypewriter = TrainerInstructionTypewriter();

  final _taskInstructionTypewriter = TrainerInstructionTypewriter();

  Timer? _countdownTimer;

  Timer? _completeTimer;

  int get _value => normalizeDotsDigitAbacusValue(widget.params['value']);

  late MatchTaskPlan _matchPlan;

  @override
  void initState() {
    super.initState();

    _matchPlan = buildMatchTaskPlan(_value);

    _startSession();
  }

  @override
  void didUpdateWidget(DotsDigitAbacusTrainer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.params != widget.params) {
      _matchPlan = buildMatchTaskPlan(_value);

      _startSession();
    }
  }

  @override
  void dispose() {
    _instructionTypewriter.cancel();

    _taskInstructionTypewriter.cancel();

    _countdownTimer?.cancel();

    _completeTimer?.cancel();

    unawaited(cancelDotsDigitAbacusAudio());

    super.dispose();
  }

  void _startSession() {
    final runToken = Object();

    _runToken = runToken;

    _instructionTypewriter.cancel();

    _taskInstructionTypewriter.cancel();

    _countdownTimer?.cancel();

    _completeTimer?.cancel();

    unawaited(cancelDotsDigitAbacusAudio());

    setState(() {
      _phase = DotsDigitAbacusPhase.instruction;

      _countdownTarget = _CountdownTarget.explain;

      _instructionLength = 0;

      _taskInstructionLength = 0;

      _countdownLabel = _countdownLabels.first;

      _completeCalled = false;

      _matchCompleteCalled = false;

      _matchDisabled = false;

      _fireworksKey = 0;

      _visibility = const TripleSceneVisibility();

      _connections.clear();

      _matchPlan = buildMatchTaskPlan(_value);
    });

    unawaited(_runInstruction(runToken));
  }

  Future<void> _runInstruction(Object runToken) async {
    final durationMs = await loadTrainerInstructionDurationMs(
      assetPath: getDotsDigitAbacusInstructionAudioAsset(),

      playbackRate: kDotsDigitAbacusAudioPlaybackRate,

      fallbackMs: kDotsDigitAbacusInstructionDurationFallbackMs,
    );

    if (!mounted || !identical(runToken, _runToken)) {
      return;
    }

    _instructionTypewriter.start(
      text: kDotsDigitAbacusInstructionText,

      durationMs: durationMs,

      isCurrent: () => mounted && identical(runToken, _runToken),

      onLength: (length) {
        if (!mounted || !identical(runToken, _runToken)) {
          return;
        }

        setState(() => _instructionLength = length);
      },
    );

    await playDotsDigitAbacusInstruction();

    if (!mounted || !identical(runToken, _runToken)) {
      return;
    }

    _instructionTypewriter.cancel();

    setState(() {
      _instructionLength = kDotsDigitAbacusInstructionText.length;

      _countdownTarget = _CountdownTarget.explain;

      _phase = DotsDigitAbacusPhase.countdown;
    });

    _startCountdown(runToken);
  }

  Future<void> _runTaskInstruction(Object runToken) async {
    final durationMs = await loadTrainerInstructionDurationMs(
      assetPath: getDotsDigitAbacusTaskInstructionAudioAsset(),

      playbackRate: kDotsDigitAbacusAudioPlaybackRate,

      fallbackMs: kDotsDigitAbacusTaskInstructionDurationFallbackMs,
    );

    if (!mounted || !identical(runToken, _runToken)) {
      return;
    }

    _taskInstructionTypewriter.start(
      text: kDotsDigitAbacusTaskInstructionText,

      durationMs: durationMs,

      isCurrent: () => mounted && identical(runToken, _runToken),

      onLength: (length) {
        if (!mounted || !identical(runToken, _runToken)) {
          return;
        }

        setState(() => _taskInstructionLength = length);
      },
    );

    await playDotsDigitAbacusTaskInstruction();

    if (!mounted || !identical(runToken, _runToken)) {
      return;
    }

    _taskInstructionTypewriter.cancel();

    setState(() {
      _taskInstructionLength = kDotsDigitAbacusTaskInstructionText.length;

      _countdownTarget = _CountdownTarget.match;

      _phase = DotsDigitAbacusPhase.taskCountdown;
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
        setState(() {
          _phase = _countdownTarget == _CountdownTarget.explain
              ? DotsDigitAbacusPhase.explain
              : DotsDigitAbacusPhase.match;
        });

        if (_countdownTarget == _CountdownTarget.explain) {
          unawaited(_runExplain(runToken));
        }

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

  void _patchVisibility(
    TripleSceneVisibility Function(TripleSceneVisibility current) patch,
  ) {
    if (!mounted) {
      return;
    }

    setState(() => _visibility = patch(_visibility));
  }

  Future<void> _runExplain(Object runToken) async {
    final value = _value;

    _patchVisibility(
      (_) => const TripleSceneVisibility(showDots: true, visibleDotCount: 0),
    );

    for (var digit = getExplainDotCountStart(value); digit <= value; digit++) {
      if (!mounted || !identical(runToken, _runToken)) {
        return;
      }

      _patchVisibility((current) => current.copyWith(visibleDotCount: digit));

      await playDotsDigitAbacusCountDigitAudio(digit);

      if (!mounted || !identical(runToken, _runToken)) {
        return;
      }

      if (digit < value) {
        await Future<void>.delayed(
          Duration(milliseconds: dotsDigitAbacusCountPauseMs),
        );
      }
    }

    if (!mounted || !identical(runToken, _runToken)) {
      return;
    }

    await playDotsDigitAbacusEqualsDigitBridge(
      onStarted: () {
        _patchVisibility(
          (current) => current.copyWith(showDigitEquals: true, showDigit: true),
        );
      },
    );

    if (!mounted || !identical(runToken, _runToken)) {
      return;
    }

    await playDotsDigitAbacusCountDigitAudio(value);

    if (!mounted || !identical(runToken, _runToken)) {
      return;
    }

    _patchVisibility((current) => current.copyWith(digitPulseActive: true));

    await Future<void>.delayed(Duration(milliseconds: dotsDigitAbacusPulseMs));

    _patchVisibility((current) => current.copyWith(digitPulseActive: false));

    if (!mounted || !identical(runToken, _runToken)) {
      return;
    }

    await playDotsDigitAbacusAbacusMatchBridge(
      onStarted: () {
        _patchVisibility(
          (current) =>
              current.copyWith(showAbacusEquals: true, showAbacus: true),
        );
      },
    );

    if (!mounted || !identical(runToken, _runToken)) {
      return;
    }

    _patchVisibility((current) => current.copyWith(abacusPulseActive: true));

    await Future<void>.delayed(Duration(milliseconds: dotsDigitAbacusPulseMs));

    if (!mounted || !identical(runToken, _runToken)) {
      return;
    }

    setState(() => _phase = DotsDigitAbacusPhase.taskInstruction);

    unawaited(_runTaskInstruction(runToken));
  }

  void _handleConnect(MatchTaskConnection connection) {
    setState(() => _connections.add(connection));
  }

  void _handleMatchComplete() {
    if (_matchCompleteCalled) {
      return;
    }

    _matchCompleteCalled = true;

    setState(() {
      _matchDisabled = true;

      _fireworksKey += 1;
    });

    _completeTimer?.cancel();

    _completeTimer = Timer(
      const Duration(milliseconds: kDotsDigitAbacusMatchSuccessMs),

      _finishTrainer,
    );
  }

  void _finishTrainer() {
    if (_completeCalled) {
      return;
    }

    _completeTimer?.cancel();

    _completeTimer = Timer(
      const Duration(milliseconds: TrainerTimings.completeDelayMs),
      () {
        if (!mounted || _completeCalled) {
          return;
        }

        _completeCalled = true;

        widget.onComplete?.call();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_phase == DotsDigitAbacusPhase.instruction) {
      return TrainerInstructionScene(
        length: _instructionLength,
        text: kDotsDigitAbacusInstructionText,
      );
    }

    if (_phase == DotsDigitAbacusPhase.taskInstruction) {
      return TrainerInstructionScene(
        length: _taskInstructionLength,
        text: kDotsDigitAbacusTaskInstructionText,
      );
    }

    if (_phase == DotsDigitAbacusPhase.countdown ||
        _phase == DotsDigitAbacusPhase.taskCountdown) {
      return TrainerScene(
        child: Center(
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
      );
    }

    if (_phase == DotsDigitAbacusPhase.match) {
      return TrainerScene(
        child: AnswerFireworksBurst(
          burstKey: _fireworksKey,
          child: MatchTaskBoard(
            connections: List.unmodifiable(_connections),
            disabled: _matchDisabled,
            onAllConnected: _handleMatchComplete,
            onConnect: _handleConnect,
            plan: _matchPlan,
          ),
        ),
      );
    }

    return TrainerScene(
      child: TripleScene(value: _value, visibility: _visibility),
    );
  }
}
