import 'dart:async';

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/math/fruit_count_tap/fruit_count_tap_layout.dart';
import 'package:larnes_mobile/trainers/math/fruit_count_tap/fruit_count_tap_model.dart';
import 'package:larnes_mobile/trainers/math/fruit_count_tap/fruit_field_scene.dart';
import 'package:larnes_mobile/trainers/math/fruit_count_tap/fruit_icon.dart';
import 'package:larnes_mobile/trainers/shared/numeric_choice_bar.dart';
import 'package:larnes_mobile/trainers/shared/seeded_rng.dart';
import 'package:larnes_mobile/trainers/shared/trainer_timings.dart';

const _wrongFeedbackMs = TrainerTimings.wrongFeedbackMs;
const _completeDelayMs = TrainerTimings.completeDelayMs;

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
  late final List<PlacedFruit> _fruits;
  late final List<int> _answerChoices;
  late final int _targetCount;

  int? _wrongValue;
  int? _selectedValue;
  bool _isCompleted = false;
  bool _completeCalled = false;
  Timer? _completeTimer;

  @override
  void initState() {
    super.initState();
    _targetCount = widget.params['targetCount'] as int? ?? 0;
    _answerChoices =
        getAnswerChoices(widget.params['answerRangeStart'] as int? ?? 0);
    _fruits = _buildFruits();
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

  FruitSlug get _targetFruit =>
      normalizeFruitSlug(widget.params['targetFruit'] as String? ?? 'watermelon');

  void _handleSelect(int value) {
    if (_isCompleted) {
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
    Future<void>.delayed(const Duration(milliseconds: _wrongFeedbackMs), () {
      if (!mounted) {
        return;
      }
      setState(() {
        if (_wrongValue == value) {
          _wrongValue = null;
        }
      });
    });
  }

  void _scheduleComplete() {
    if (_completeCalled || widget.onComplete == null) {
      return;
    }

    _completeCalled = true;
    _completeTimer = Timer(
      const Duration(milliseconds: _completeDelayMs),
      () {
        if (mounted) {
          widget.onComplete?.call();
        }
      },
    );
  }

  @override
  void dispose() {
    _completeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = fruitLabels[_targetFruit] ?? 'фруктов';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Сколько ',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF4B5563),
              ),
            ),
            FruitIcon(fruit: _targetFruit, size: 28),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                '$label ты видишь?',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF4B5563),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        FruitFieldScene(fruits: _fruits),
        const SizedBox(height: 16),
        NumericChoiceBar(
          choices: _answerChoices,
          disabled: _isCompleted,
          onSelect: _handleSelect,
          selectedValue: _selectedValue,
          wrongValue: _wrongValue,
        ),
        if (_isCompleted) ...[
          const SizedBox(height: 12),
          const Text(
            'Молодец!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF16A34A),
            ),
          ),
        ],
      ],
    );
  }
}
