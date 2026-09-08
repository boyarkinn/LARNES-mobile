import 'dart:async';

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/math/fruit_count_tap/fruit_answer_bar_layout.dart';
import 'package:larnes_mobile/trainers/math/fruit_count_tap/fruit_count_tap_audio.dart';
import 'package:larnes_mobile/trainers/math/fruit_count_tap/fruit_count_tap_layout.dart';
import 'package:larnes_mobile/trainers/math/fruit_count_tap/fruit_count_tap_model.dart';
import 'package:larnes_mobile/trainers/math/fruit_count_tap/fruit_field_scene.dart';
import 'package:larnes_mobile/trainers/math/fruit_count_tap/fruit_reveal.dart';
import 'package:larnes_mobile/trainers/runtime/runtime_snapshot.dart';
import 'package:larnes_mobile/trainers/shared/instruction/load_trainer_instruction_duration.dart';
import 'package:larnes_mobile/trainers/shared/instruction/trainer_instruction_scene.dart';
import 'package:larnes_mobile/trainers/shared/instruction/trainer_instruction_typewriter.dart';
import 'package:larnes_mobile/trainers/shared/numeric_choice_bar.dart';
import 'package:larnes_mobile/trainers/shared/seeded_rng.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';
import 'package:larnes_mobile/trainers/shared/trainer_timings.dart';

enum FruitCountTapPhase { instruction, countdown, announce, play }

/// Web v2: `platform/src/trainers/math/fruit-count-tap/component.tsx`
class FruitCountTapTrainer extends StatefulWidget {
  const FruitCountTapTrainer({
    super.key,
    required this.params,
    this.onComplete,
  });

  final Map<String, dynamic> params;
  final VoidCallback? onComplete;

  @override
  State<FruitCountTapTrainer> createState() => _FruitCountTapTrainerState();
}

class _FruitCountTapTrainerState extends State<FruitCountTapTrainer> {
  static const _countdownLabels = ['3', '2', '1', 'СТАРТ'];
  static const _countdownStepMs = 750;
  static const _countdownColor = Color(0xFFDC2626);

  var _layoutSalt = 0;
  late List<PlacedFruit> _fruits;
  late final List<int> _answerChoices;
  late final int _targetCount;

  FruitCountTapPhase _phase = FruitCountTapPhase.instruction;
  String _countdownLabel = _countdownLabels.first;
  var _instructionLength = 0;
  int? _wrongValue;
  int? _selectedValue;
  var _isCompleted = false;
  var _isFruitRevealComplete = false;
  var _isAnswerRevealComplete = false;
  var _completeCalled = false;
  Object _runToken = Object();

  final _instructionTypewriter = TrainerInstructionTypewriter();
  Timer? _countdownTimer;
  Timer? _instructionDelayTimer;
  Timer? _fruitRevealTimer;
  Timer? _answerRevealTimer;
  Timer? _completeTimer;

  @override
  void initState() {
    super.initState();
    _startSession();
  }

  @override
  void didUpdateWidget(FruitCountTapTrainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.params != widget.params) {
      _startSession();
    }
  }

  @override
  void dispose() {
    _instructionTypewriter.cancel();
    _countdownTimer?.cancel();
    _instructionDelayTimer?.cancel();
    _fruitRevealTimer?.cancel();
    _answerRevealTimer?.cancel();
    _completeTimer?.cancel();
    unawaited(cancelFruitCountTapAudio());
    super.dispose();
  }

  void _startSession() {
    final runToken = Object();
    _runToken = runToken;
    _instructionTypewriter.cancel();
    _countdownTimer?.cancel();
    _instructionDelayTimer?.cancel();
    _fruitRevealTimer?.cancel();
    _answerRevealTimer?.cancel();
    _completeTimer?.cancel();
    unawaited(cancelFruitCountTapAudio());

    _layoutSalt = createLayoutSalt();
    _targetCount = widget.params['targetCount'] as int? ?? 0;
    _answerChoices =
        getAnswerChoices(widget.params['answerRangeStart'] as int? ?? 0);
    _fruits = _buildFruits();

    setState(() {
      _phase = FruitCountTapPhase.instruction;
      _instructionLength = 0;
      _countdownLabel = _countdownLabels.first;
      _wrongValue = null;
      _selectedValue = null;
      _isCompleted = false;
      _isFruitRevealComplete = false;
      _isAnswerRevealComplete = false;
      _completeCalled = false;
    });

    unawaited(_runInstruction(runToken));
  }

  List<PlacedFruit> _buildFruits() {
    final targetFruit =
        normalizeFruitSlug(widget.params['targetFruit'] as String? ?? 'watermelon');
    final fruitTypeCount = widget.params['fruitTypeCount'] as int? ?? 1;
    final totalFruits = widget.params['totalFruits'] as int? ?? 1;
    final answerRangeStart = widget.params['answerRangeStart'] as int? ?? 0;

    final snapshotSeed = readTrainerSnapshotSeed(
      'fruit-count-tap',
      widget.params,
    );
    final rng = snapshotSeed == null
        ? createSeededRng(
            hashParamsSeed([
              targetFruit,
              _targetCount,
              fruitTypeCount,
              totalFruits,
              answerRangeStart,
              _layoutSalt,
            ]),
          )
        : TrainerSnapshotRandom(snapshotSeed).nextDouble;
    final tokens = buildFruitTokens(
      BuildFruitFieldInput(
        answerRangeStart: answerRangeStart,
        fruitTypeCount: fruitTypeCount,
        rng: rng,
        targetCount: _targetCount,
        targetFruit: targetFruit,
        totalFruits: totalFruits,
      ),
    );

    return placeFruitTokens(tokens, rng);
  }

  Future<void> _runInstruction(Object runToken) async {
    final durationMs = await loadTrainerInstructionDurationMs(
      assetPath: getFruitCountTapInstructionAudioAsset(),
      playbackRate: kFruitCountTapInstructionPlaybackRate,
      fallbackMs: kFruitCountTapInstructionDurationFallbackMs,
    ).timeout(
      const Duration(milliseconds: kFruitCountTapInstructionDurationFallbackMs),
      onTimeout: () => kFruitCountTapInstructionDurationFallbackMs,
    );
    if (!mounted || !identical(runToken, _runToken)) {
      return;
    }

    _instructionTypewriter.start(
      text: fruitCountTapInstructionText,
      durationMs: durationMs,
      isCurrent: () => mounted && identical(runToken, _runToken),
      onLength: (length) {
        if (!mounted || !identical(runToken, _runToken)) {
          return;
        }
        setState(() => _instructionLength = length);
      },
    );

    unawaited(playFruitCountTapInstruction());
    _instructionDelayTimer?.cancel();
    _instructionDelayTimer = Timer(Duration(milliseconds: durationMs), () {
      if (!mounted || !identical(runToken, _runToken)) {
        return;
      }

      _instructionTypewriter.cancel();
      setState(() {
        _instructionLength = fruitCountTapInstructionText.length;
        _phase = FruitCountTapPhase.countdown;
      });
      _runCountdown(runToken);
    });
  }

  void _runCountdown(Object runToken) {
    _countdownTimer?.cancel();
    var index = 0;

    void showNext() {
      if (!mounted || !identical(runToken, _runToken)) {
        return;
      }

      if (index >= _countdownLabels.length) {
        setState(() => _phase = FruitCountTapPhase.announce);
        unawaited(_runAnnounce(runToken));
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

  Future<void> _runAnnounce(Object runToken) async {
    final targetFruit =
        normalizeFruitSlug(widget.params['targetFruit'] as String? ?? 'watermelon');

    try {
      await playFruitCountTapTargetFruit(targetFruit)
          .timeout(const Duration(seconds: 2));
    } catch (_) {
      // Tests / missing assets — still reveal the field.
    }

    if (!mounted || !identical(runToken, _runToken)) {
      return;
    }

    setState(() => _phase = FruitCountTapPhase.play);
    _scheduleFruitReveal();
  }

  void _scheduleFruitReveal() {
    _fruitRevealTimer?.cancel();
    _answerRevealTimer?.cancel();

    if (_fruits.isEmpty) {
      setState(() => _isFruitRevealComplete = true);
      _scheduleAnswerReveal();
      return;
    }

    setState(() {
      _isFruitRevealComplete = false;
      _isAnswerRevealComplete = false;
    });

    _fruitRevealTimer = Timer(
      Duration(milliseconds: getFruitRevealTotalMs(_fruits.length)),
      () {
        if (!mounted) {
          return;
        }
        setState(() => _isFruitRevealComplete = true);
        _scheduleAnswerReveal();
      },
    );
  }

  void _scheduleAnswerReveal() {
    _answerRevealTimer?.cancel();

    if (_answerChoices.isEmpty) {
      setState(() => _isAnswerRevealComplete = true);
      return;
    }

    setState(() => _isAnswerRevealComplete = false);

    _answerRevealTimer = Timer(
      Duration(milliseconds: getAnswerRevealTotalMs(_answerChoices.length)),
      () {
        if (!mounted) {
          return;
        }
        setState(() => _isAnswerRevealComplete = true);
      },
    );
  }

  void _handleSelect(int value) {
    if (_isCompleted || !_isAnswerRevealComplete) {
      return;
    }

    if (value == _targetCount) {
      setState(() {
        _wrongValue = null;
        _selectedValue = value;
        _isCompleted = true;
      });
      _scheduleComplete();
      return;
    }

    setState(() => _wrongValue = value);
    Future<void>.delayed(
      const Duration(milliseconds: TrainerTimings.wrongFeedbackMs),
      () {
        if (!mounted) {
          return;
        }
        setState(() {
          if (_wrongValue == value) {
            _wrongValue = null;
          }
        });
      },
    );
  }

  void _scheduleComplete() {
    if (_completeCalled || widget.onComplete == null) {
      return;
    }

    _completeCalled = true;
    _completeTimer = Timer(
      const Duration(milliseconds: TrainerTimings.completeDelayMs),
      () {
        if (mounted) {
          widget.onComplete?.call();
        }
      },
    );
  }

  Widget _buildPlayBody(BoxConstraints constraints) {
    final answerLayout = computeFruitAnswerBarLayout(
      viewportWidth: constraints.maxWidth,
      viewportHeight: constraints.maxHeight,
    );

    return TrainerSceneColumn(
      body: FruitFieldScene(fruits: _fruits),
      footer: _isFruitRevealComplete
          ? Padding(
              padding: EdgeInsets.fromLTRB(
                answerLayout.horizontalPadding,
                answerLayout.paddingTop,
                answerLayout.horizontalPadding,
                answerLayout.paddingBottom,
              ),
              child: NumericChoiceBar(
                choices: _answerChoices,
                disabled: _isCompleted || !_isAnswerRevealComplete,
                enterDelayMsForIndex: (index) =>
                    getAnswerRevealDelayMs(index, _answerChoices.length),
                buttonHeight: answerLayout.buttonHeight,
                fontSize: answerLayout.fontSize,
                onSelect: _handleSelect,
                selectedValue: _selectedValue,
                wrongValue: _wrongValue,
              ),
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return TrainerScene(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return switch (_phase) {
            FruitCountTapPhase.instruction => TrainerInstructionScene(
              length: _instructionLength,
              text: fruitCountTapInstructionText,
            ),
            FruitCountTapPhase.countdown => Center(
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
            FruitCountTapPhase.announce => const SizedBox.expand(),
            FruitCountTapPhase.play => _buildPlayBody(constraints),
          };
        },
      ),
    );
  }
}
