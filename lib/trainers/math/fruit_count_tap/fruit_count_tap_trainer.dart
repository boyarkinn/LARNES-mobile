import 'dart:async';

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/math/fruit_count_tap/fruit_answer_bar_layout.dart';
import 'package:larnes_mobile/trainers/math/fruit_count_tap/fruit_count_tap_layout.dart';
import 'package:larnes_mobile/trainers/math/fruit_count_tap/fruit_count_tap_model.dart';
import 'package:larnes_mobile/trainers/math/fruit_count_tap/fruit_field_scene.dart';
import 'package:larnes_mobile/trainers/math/fruit_count_tap/fruit_reveal.dart';
import 'package:larnes_mobile/trainers/shared/numeric_choice_bar.dart';
import 'package:larnes_mobile/trainers/shared/seeded_rng.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';
import 'package:larnes_mobile/trainers/shared/trainer_timings.dart';

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
  late final int _layoutSalt;
  late final List<PlacedFruit> _fruits;
  late final List<int> _answerChoices;
  late final int _targetCount;

  int? _wrongValue;
  int? _selectedValue;
  var _isCompleted = false;
  var _isFruitRevealComplete = false;
  var _isAnswerRevealComplete = false;
  var _completeCalled = false;
  Timer? _fruitRevealTimer;
  Timer? _answerRevealTimer;
  Timer? _completeTimer;

  @override
  void initState() {
    super.initState();
    _layoutSalt = createLayoutSalt();
    _targetCount = widget.params['targetCount'] as int? ?? 0;
    _answerChoices =
        getAnswerChoices(widget.params['answerRangeStart'] as int? ?? 0);
    _fruits = _buildFruits();
    _scheduleFruitReveal();
  }

  List<PlacedFruit> _buildFruits() {
    final targetFruit =
        normalizeFruitSlug(widget.params['targetFruit'] as String? ?? 'watermelon');
    final fruitTypeCount = widget.params['fruitTypeCount'] as int? ?? 1;
    final totalFruits = widget.params['totalFruits'] as int? ?? 1;
    final answerRangeStart = widget.params['answerRangeStart'] as int? ?? 0;

    final seed = hashParamsSeed([
      targetFruit,
      _targetCount,
      fruitTypeCount,
      totalFruits,
      answerRangeStart,
      _layoutSalt,
    ]);
    final rng = createSeededRng(seed);
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

  @override
  void dispose() {
    _fruitRevealTimer?.cancel();
    _answerRevealTimer?.cancel();
    _completeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
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
      },
    );
  }
}
