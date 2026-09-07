import 'dart:async';

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/math/digit_find_tap/digit_field_scene.dart';
import 'package:larnes_mobile/trainers/math/digit_find_tap/digit_find_tap_audio.dart';
import 'package:larnes_mobile/trainers/math/digit_find_tap/digit_find_tap_layout.dart';
import 'package:larnes_mobile/trainers/math/digit_find_tap/digit_find_tap_model.dart';
import 'package:larnes_mobile/trainers/math/fruit_count_tap/fruit_reveal.dart';
import 'package:larnes_mobile/trainers/runtime/runtime_snapshot.dart';
import 'package:larnes_mobile/trainers/shared/instruction/load_trainer_instruction_duration.dart';
import 'package:larnes_mobile/trainers/shared/instruction/trainer_instruction_scene.dart';
import 'package:larnes_mobile/trainers/shared/instruction/trainer_instruction_typewriter.dart';
import 'package:larnes_mobile/trainers/shared/seeded_rng.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';
import 'package:larnes_mobile/trainers/shared/trainer_timings.dart';

enum DigitFindTapPhase { instruction, countdown, play }

/// Web v2: `platform/src/trainers/math/digit-find-tap/component.tsx`
class DigitFindTapTrainer extends StatefulWidget {
  const DigitFindTapTrainer({
    super.key,
    required this.params,
    this.onComplete,
  });

  final Map<String, dynamic> params;
  final VoidCallback? onComplete;

  @override
  State<DigitFindTapTrainer> createState() => _DigitFindTapTrainerState();
}

class _DigitFindTapTrainerState extends State<DigitFindTapTrainer> {
  static const _countdownLabels = ['3', '2', '1', 'СТАРТ'];
  static const _countdownStepMs = 750;
  static const _countdownColor = Color(0xFFDC2626);

  var _layoutSalt = 0;
  late List<PlacedDigit> _digits;

  DigitFindTapPhase _phase = DigitFindTapPhase.instruction;
  String _countdownLabel = _countdownLabels.first;
  var _instructionLength = 0;
  final Set<String> _foundIds = {};
  String? _wrongId;
  var _isCompleted = false;
  var _isRevealComplete = false;
  var _completeCalled = false;
  Object _runToken = Object();

  final _instructionTypewriter = TrainerInstructionTypewriter();
  Timer? _countdownTimer;
  Timer? _revealTimer;
  Timer? _completeTimer;

  @override
  void initState() {
    super.initState();
    _startSession();
  }

  @override
  void didUpdateWidget(DigitFindTapTrainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.params != widget.params) {
      _startSession();
    }
  }

  @override
  void dispose() {
    _instructionTypewriter.cancel();
    _countdownTimer?.cancel();
    _revealTimer?.cancel();
    _completeTimer?.cancel();
    unawaited(cancelDigitFindTapAudio());
    super.dispose();
  }

  void _startSession() {
    final runToken = Object();
    _runToken = runToken;
    _instructionTypewriter.cancel();
    _countdownTimer?.cancel();
    _revealTimer?.cancel();
    _completeTimer?.cancel();
    unawaited(cancelDigitFindTapAudio());

    _layoutSalt = createLayoutSalt();
    _digits = _buildDigits();
    _foundIds.clear();

    setState(() {
      _phase = DigitFindTapPhase.instruction;
      _instructionLength = 0;
      _countdownLabel = _countdownLabels.first;
      _wrongId = null;
      _isCompleted = false;
      _isRevealComplete = false;
      _completeCalled = false;
    });

    unawaited(_runInstruction(runToken));
  }

  List<PlacedDigit> _buildDigits() {
    final targetDigit = normalizeTargetDigit(widget.params['digit'] as num? ?? 0);
    final targetCount = widget.params['targetCount'] as int? ?? 1;
    final distractorCount = widget.params['distractorCount'] as int? ?? 0;

    final snapshotSeed = readTrainerSnapshotSeed(
      'digit-find-tap',
      widget.params,
    );
    final rng = snapshotSeed == null
        ? createSeededRng(
            hashParamsSeed([
              targetDigit,
              targetCount,
              distractorCount,
              _layoutSalt,
            ]),
          )
        : TrainerSnapshotRandom(snapshotSeed).nextDouble;
    final tokens = buildDigitTokens(
      BuildDigitFieldInput(
        distractorCount: distractorCount,
        rng: rng,
        targetCount: targetCount,
        targetDigit: targetDigit,
      ),
    );

    return placeDigitTokens(tokens, rng);
  }

  Future<void> _runInstruction(Object runToken) async {
    final durationMs = await loadTrainerInstructionDurationMs(
      assetPath: getDigitFindTapInstructionAudioAsset(),
      playbackRate: kDigitFindTapInstructionPlaybackRate,
      fallbackMs: kDigitFindTapInstructionDurationFallbackMs,
    );
    if (!mounted || !identical(runToken, _runToken)) {
      return;
    }

    _instructionTypewriter.start(
      text: digitFindTapInstructionText,
      durationMs: durationMs,
      isCurrent: () => mounted && identical(runToken, _runToken),
      onLength: (length) {
        if (!mounted || !identical(runToken, _runToken)) {
          return;
        }
        setState(() => _instructionLength = length);
      },
    );

    await playDigitFindTapInstruction();
    if (!mounted || !identical(runToken, _runToken)) {
      return;
    }

    _instructionTypewriter.cancel();
    setState(() {
      _instructionLength = digitFindTapInstructionText.length;
      _phase = DigitFindTapPhase.countdown;
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
        setState(() => _phase = DigitFindTapPhase.play);
        _scheduleReveal();
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

  void _scheduleReveal() {
    _revealTimer?.cancel();

    if (_digits.isEmpty) {
      setState(() => _isRevealComplete = true);
      return;
    }

    setState(() => _isRevealComplete = false);

    _revealTimer = Timer(
      Duration(milliseconds: getFruitRevealTotalMs(_digits.length)),
      () {
        if (!mounted) {
          return;
        }
        setState(() => _isRevealComplete = true);
      },
    );
  }

  void _handleTap(String id) {
    if (_isCompleted || !_isRevealComplete || _foundIds.contains(id)) {
      return;
    }

    final tokenIndex = _digits.indexWhere((digit) => digit.id == id);
    if (tokenIndex < 0) {
      return;
    }
    final token = _digits[tokenIndex];

    if (!token.isTarget) {
      setState(() => _wrongId = id);
      Future<void>.delayed(
        const Duration(milliseconds: TrainerTimings.wrongFeedbackMs),
        () {
          if (!mounted) {
            return;
          }
          setState(() {
            if (_wrongId == id) {
              _wrongId = null;
            }
          });
        },
      );
      return;
    }

    setState(() => _foundIds.add(id));

    if (allTargetsFound(_foundIds, _digits)) {
      setState(() => _isCompleted = true);
      _scheduleComplete();
    }
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
    return TrainerScene(
      child: switch (_phase) {
        DigitFindTapPhase.instruction => TrainerInstructionScene(
          length: _instructionLength,
          text: digitFindTapInstructionText,
        ),
        DigitFindTapPhase.countdown => Center(
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
        DigitFindTapPhase.play => DigitFieldScene(
          digits: _digits,
          disabled: _isCompleted || !_isRevealComplete,
          foundIds: _foundIds,
          onTap: _handleTap,
          wrongId: _wrongId,
        ),
      },
    );
  }
}
