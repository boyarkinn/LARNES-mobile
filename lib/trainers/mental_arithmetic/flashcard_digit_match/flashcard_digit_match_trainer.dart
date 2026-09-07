import 'dart:async';

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/flashcard_digit_match/flashcard_digit_match_audio.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/flashcard_digit_match/flashcard_digit_match_model.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/flashcard_digit_match/match_board.dart';
import 'package:larnes_mobile/trainers/shared/instruction/load_trainer_instruction_duration.dart';
import 'package:larnes_mobile/trainers/shared/instruction/trainer_instruction_scene.dart';
import 'package:larnes_mobile/trainers/shared/instruction/trainer_instruction_typewriter.dart';
import 'package:larnes_mobile/trainers/shared/seeded_rng.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';
import 'package:larnes_mobile/trainers/shared/trainer_timings.dart';

enum FlashcardDigitMatchPhase { instruction, countdown, play }

/// Web v2: `platform/src/trainers/mental-arithmetic/flashcard-digit-match/component.tsx`
class FlashcardDigitMatchTrainer extends StatefulWidget {
  const FlashcardDigitMatchTrainer({
    super.key,
    required this.params,
    this.onComplete,
  });

  final Map<String, dynamic> params;
  final VoidCallback? onComplete;

  @override
  State<FlashcardDigitMatchTrainer> createState() =>
      _FlashcardDigitMatchTrainerState();
}

class _FlashcardDigitMatchTrainerState extends State<FlashcardDigitMatchTrainer> {
  static const _instructionTextDigits = 'Соедини флеш-карту с такой же цифрой';
  static const _instructionTextDots =
      'Соедини флеш-карту с таким же количеством точек';
  static const _countdownLabels = ['3', '2', '1', 'СТАРТ'];
  static const _countdownStepMs = 750;
  static const _countdownColor = Color(0xFFDC2626);
  static const _roundPauseMs = 700;

  late final int _pairCount;
  late final FlashcardTargetMode _targetMode;
  late final int _totalRods;
  late final List<MatchRound> _rounds;

  var _roundIndex = 0;
  FlashcardDigitMatchPhase _phase = FlashcardDigitMatchPhase.instruction;
  String _countdownLabel = _countdownLabels.first;
  var _instructionLength = 0;
  final _connections = <MatchConnection>[];
  var _isRoundComplete = false;
  var _completeCalled = false;
  Object _runToken = Object();

  final _instructionTypewriter = TrainerInstructionTypewriter();
  Timer? _countdownTimer;
  Timer? _roundTimer;

  String get _instructionText => _targetMode == FlashcardTargetMode.dots
      ? _instructionTextDots
      : _instructionTextDigits;

  MatchRound? get _currentRound =>
      _rounds.isEmpty ? null : _rounds[_roundIndex.clamp(0, _rounds.length - 1)];

  @override
  void initState() {
    super.initState();
    _startSession();
  }

  @override
  void didUpdateWidget(FlashcardDigitMatchTrainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.params != widget.params) {
      _startSession();
    }
  }

  @override
  void dispose() {
    _instructionTypewriter.cancel();
    _countdownTimer?.cancel();
    _roundTimer?.cancel();
    unawaited(cancelFlashcardDigitMatchAudio());
    super.dispose();
  }

  void _startSession() {
    final runToken = Object();
    _runToken = runToken;
    _instructionTypewriter.cancel();
    _countdownTimer?.cancel();
    _roundTimer?.cancel();
    unawaited(cancelFlashcardDigitMatchAudio());

    _pairCount = widget.params['pairCount'] as int? ?? minMatchPairs;
    _targetMode = normalizeTargetMode(widget.params['targetMode']);
    _totalRods = widget.params['totalRods'] as int? ?? 1;
    final rounds = widget.params['rounds'] as int? ?? minMatchRounds;
    final masterSeed = hashParamsSeed([
      _pairCount,
      rounds,
      _targetMode == FlashcardTargetMode.dots ? 'dots' : 'digits',
      _totalRods,
      'flashcard-digit-match',
    ]);
    _rounds = buildFlashcardMatchPlan(
      pairCount: _pairCount,
      rounds: rounds,
      totalRods: _totalRods,
      masterSeed: masterSeed,
    );
    _roundIndex = 0;
    _connections.clear();

    setState(() {
      _phase = FlashcardDigitMatchPhase.instruction;
      _instructionLength = 0;
      _countdownLabel = _countdownLabels.first;
      _isRoundComplete = false;
      _completeCalled = false;
    });

    unawaited(_runInstruction(runToken));
  }

  Future<void> _runInstruction(Object runToken) async {
    final durationMs = await loadTrainerInstructionDurationMs(
      assetPath: getFlashcardDigitMatchInstructionAudioAsset(),
      playbackRate: kFlashcardDigitMatchInstructionPlaybackRate,
      fallbackMs: kFlashcardDigitMatchInstructionDurationFallbackMs,
    );
    if (!mounted || !identical(runToken, _runToken)) {
      return;
    }

    _instructionTypewriter.start(
      text: _instructionText,
      durationMs: durationMs,
      isCurrent: () => mounted && identical(runToken, _runToken),
      onLength: (length) {
        if (!mounted || !identical(runToken, _runToken)) {
          return;
        }
        setState(() => _instructionLength = length);
      },
    );

    await playFlashcardDigitMatchInstruction();
    if (!mounted || !identical(runToken, _runToken)) {
      return;
    }

    _instructionTypewriter.cancel();
    setState(() {
      _instructionLength = _instructionText.length;
      _phase = FlashcardDigitMatchPhase.countdown;
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
        setState(() => _phase = FlashcardDigitMatchPhase.play);
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

  void _handleConnect(MatchConnection connection) {
    if (_connections.any((item) => item.leftId == connection.leftId)) {
      return;
    }

    setState(() => _connections.add(connection));

    if (isRoundComplete(_connections, _pairCount)) {
      setState(() => _isRoundComplete = true);
      _scheduleRoundAdvance();
    }
  }

  void _scheduleRoundAdvance() {
    _roundTimer?.cancel();
    final delayMs = _roundIndex + 1 < _rounds.length
        ? _roundPauseMs
        : TrainerTimings.flashcardCompleteDelayMs;

    _roundTimer = Timer(Duration(milliseconds: delayMs), () {
      if (!mounted) {
        return;
      }

      if (_roundIndex + 1 < _rounds.length) {
        setState(() {
          _roundIndex += 1;
          _connections.clear();
          _isRoundComplete = false;
        });
        return;
      }

      if (_completeCalled || widget.onComplete == null) {
        return;
      }

      _completeCalled = true;
      widget.onComplete?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_phase == FlashcardDigitMatchPhase.instruction) {
      return TrainerInstructionScene(
        length: _instructionLength,
        text: _instructionText,
      );
    }

    if (_phase == FlashcardDigitMatchPhase.countdown) {
      return TrainerScene(
        child: Center(
          child: Text(
            _countdownLabel,
            style: const TextStyle(
              fontSize: 96,
              fontWeight: FontWeight.w700,
              height: 1,
              color: _countdownColor,
            ),
          ),
        ),
      );
    }

    final currentRound = _currentRound;
    if (currentRound == null) {
      return const SizedBox.shrink();
    }

    return TrainerScene(
      child: MatchBoard(
        connections: _connections,
        disabled: _isRoundComplete,
        onConnect: _handleConnect,
        round: currentRound,
        targetMode: _targetMode,
        totalRods: _totalRods,
      ),
    );
  }
}
