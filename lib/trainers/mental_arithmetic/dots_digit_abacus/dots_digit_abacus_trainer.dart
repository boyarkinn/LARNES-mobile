import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:larnes_mobile/trainers/mental_arithmetic/dots_digit_abacus/dots_digit_abacus_audio.dart';

import 'package:larnes_mobile/trainers/mental_arithmetic/dots_digit_abacus/dots_digit_abacus_experience_scene.dart';

import 'package:larnes_mobile/trainers/mental_arithmetic/dots_digit_abacus/dots_digit_abacus_model.dart';

import 'package:larnes_mobile/trainers/mental_arithmetic/dots_digit_abacus/dots_digit_abacus_sizes.dart';

import 'package:larnes_mobile/trainers/mental_arithmetic/dots_digit_abacus/match_task_model.dart';

import 'package:larnes_mobile/trainers/mental_arithmetic/dots_digit_abacus/triple_scene.dart';

import 'package:larnes_mobile/trainers/runtime/runtime_snapshot.dart';

import 'package:larnes_mobile/trainers/shared/instruction/load_trainer_instruction_duration.dart';

import 'package:larnes_mobile/trainers/shared/instruction/trainer_instruction_scene.dart';

import 'package:larnes_mobile/trainers/shared/instruction/trainer_instruction_typewriter.dart';

import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';
import 'package:larnes_mobile/trainers/runtime/trainer_telemetry.dart';

import 'package:larnes_mobile/trainers/shared/trainer_timings.dart';

enum DotsDigitAbacusPhase {
  instruction,

  countdown,

  explain,

  taskInstruction,

  match,
}

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

  var _phase = DotsDigitAbacusPhase.instruction;

  var _countdownLabel = _countdownLabels.first;

  var _instructionLength = 0;

  var _taskInstructionLength = 0;

  var _completeCalled = false;

  var _matchCompleteCalled = false;

  var _matchDisabled = false;

  var _visibility = const TripleSceneVisibility();

  final _connections = <MatchTaskConnection>[];

  Object _runToken = Object();

  final _instructionTypewriter = TrainerInstructionTypewriter();

  Timer? _countdownTimer;

  Timer? _completeTimer;

  int get _value => normalizeDotsDigitAbacusValue(widget.params['value']);

  late MatchTaskPlan _matchPlan;
  final _sessionMatchSeed = math.Random().nextInt(0x7FFFFFFF);

  MatchTaskPlan _buildPlan() {
    final seed = readTrainerSnapshotSeed('dots-digit-abacus', widget.params);
    return buildMatchTaskPlan(_value, seed ?? _sessionMatchSeed);
  }

  @override
  void initState() {
    super.initState();

    _matchPlan = _buildPlan();

    _startSession();
  }

  @override
  void didUpdateWidget(DotsDigitAbacusTrainer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.params != widget.params) {
      _matchPlan = _buildPlan();

      _startSession();
    }
  }

  @override
  void dispose() {
    _instructionTypewriter.cancel();

    _countdownTimer?.cancel();

    _completeTimer?.cancel();

    unawaited(cancelDotsDigitAbacusAudio());

    super.dispose();
  }

  void _startSession() {
    final runToken = Object();

    _runToken = runToken;

    _instructionTypewriter.cancel();

    _countdownTimer?.cancel();

    _completeTimer?.cancel();

    unawaited(cancelDotsDigitAbacusAudio());

    setState(() {
      _phase = DotsDigitAbacusPhase.instruction;

      _countdownLabel = _countdownLabels.first;

      _instructionLength = 0;

      _taskInstructionLength = 0;

      _completeCalled = false;

      _matchCompleteCalled = false;

      _matchDisabled = false;

      _visibility = const TripleSceneVisibility();

      _connections.clear();

      _matchPlan = _buildPlan();
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
        if (mounted && identical(runToken, _runToken)) {
          setState(() => _instructionLength = length);
        }
      },
    );

    await playDotsDigitAbacusInstruction();

    if (!mounted || !identical(runToken, _runToken)) {
      return;
    }

    _instructionTypewriter.cancel();

    setState(() {
      _instructionLength = kDotsDigitAbacusInstructionText.length;
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

    _instructionTypewriter.start(
      text: kDotsDigitAbacusTaskInstructionText,
      durationMs: durationMs,
      isCurrent: () =>
          mounted &&
          identical(runToken, _runToken) &&
          _phase == DotsDigitAbacusPhase.taskInstruction,
      onLength: (length) {
        if (mounted && identical(runToken, _runToken)) {
          setState(() => _taskInstructionLength = length);
        }
      },
    );

    await playDotsDigitAbacusTaskInstruction();

    if (!mounted || !identical(runToken, _runToken)) {
      return;
    }

    _instructionTypewriter.cancel();
    setState(() {
      _taskInstructionLength = kDotsDigitAbacusTaskInstructionText.length;
      _phase = DotsDigitAbacusPhase.match;
    });
  }

  void _startCountdown(Object runToken) {
    _countdownTimer?.cancel();

    var index = 0;

    void tick() {
      if (!mounted || !identical(runToken, _runToken)) {
        return;
      }

      if (index >= _countdownLabels.length) {
        setState(() => _phase = DotsDigitAbacusPhase.explain);
        unawaited(_runExplain(runToken));

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

    DateTime? abacusShownAt;
    await playDotsDigitAbacusAbacusMatchBridge(
      onStarted: () {
        abacusShownAt = DateTime.now();
        _patchVisibility(
          (current) => current.copyWith(
            showAbacusEquals: true,
            showAbacus: true,
            showAbacusValue: true,
          ),
        );
      },
    );

    if (!mounted || !identical(runToken, _runToken)) {
      return;
    }

    _patchVisibility((current) => current.copyWith(abacusPulseActive: true));

    final abacusElapsedMs = abacusShownAt == null
        ? 0
        : DateTime.now().difference(abacusShownAt!).inMilliseconds;
    final abacusRemainingMs = kDotsDigitAbacusAbacusDisplayMs - abacusElapsedMs;
    await Future<void>.delayed(
      Duration(milliseconds: abacusRemainingMs > 0 ? abacusRemainingMs : 0),
    );

    if (!mounted || !identical(runToken, _runToken)) {
      return;
    }

    _patchVisibility((current) => current.copyWith(abacusPulseActive: false));
    setState(() => _phase = DotsDigitAbacusPhase.taskInstruction);

    unawaited(_runTaskInstruction(runToken));
  }

  void _handleConnect(MatchTaskConnection connection) {
    TrainerTelemetryScope.maybeOf(context)?.interaction(
      correct: true,
      progressCurrent: _connections.length + 1,
      progressTotal: 2,
    );
    setState(() => _connections.add(connection));
  }

  void _handleMatchComplete() {
    if (_matchCompleteCalled) {
      return;
    }

    _matchCompleteCalled = true;

    setState(() {
      _matchDisabled = true;
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

    if (_phase == DotsDigitAbacusPhase.countdown) {
      return TrainerScene(
        child: Center(
          child: Text(
            _countdownLabel,
            style: TextStyle(
              fontSize: 96,
              fontWeight: FontWeight.w700,
              color: const Color(kDotsDigitAbacusObjectColor),
              height: 1,
            ),
          ),
        ),
      );
    }

    return TrainerScene(
      child: DotsDigitAbacusExperienceScene(
        completed: _matchDisabled,
        connections: List.unmodifiable(_connections),
        disabled:
            _matchDisabled || _phase == DotsDigitAbacusPhase.taskInstruction,
        onAllConnected: _handleMatchComplete,
        onConnect: _handleConnect,
        onWrongAttempt: () {
          TrainerTelemetryScope.maybeOf(context)?.interaction(
            correct: false,
            errorCode: 'wrong_match',
            progressCurrent: _connections.length,
            progressTotal: 2,
          );
        },
        plan: _matchPlan,
        practice: _phase != DotsDigitAbacusPhase.explain,
        taskInstructionLength: _taskInstructionLength,
        taskInstructionVisible: _phase == DotsDigitAbacusPhase.taskInstruction,
        visibility: _visibility,
      ),
    );
  }
}
