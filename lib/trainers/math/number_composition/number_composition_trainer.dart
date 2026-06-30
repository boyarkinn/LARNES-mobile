import 'dart:async';

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/math/number_composition/dot_choice_bar.dart';
import 'package:larnes_mobile/trainers/math/number_composition/equation_scene.dart';
import 'package:larnes_mobile/trainers/math/number_composition/number_composition_model.dart';
import 'package:larnes_mobile/trainers/shared/numeric_choice_bar.dart';
import 'package:larnes_mobile/trainers/shared/trainer_timings.dart';

const _wrongFeedbackMs = TrainerTimings.wrongFeedbackMs;
const _phaseAdvanceMs = TrainerTimings.phaseAdvanceMs;
const _completeDelayMs = TrainerTimings.completeDelayMs;

String _phasePrompt(CompositionPhase phase, int whole, int knownPart) {
  switch (phase) {
    case 'demo-dots':
      return 'Смотри: из точек складывается число.';
    case 'demo-digits':
      return 'То же самое с цифрами.';
    case 'practice-dots':
      return 'Сколько точек добавить, чтобы получилось $whole?';
    default:
      return 'Сколько добавить к $knownPart, чтобы получилось $whole?';
  }
}

class NumberCompositionTrainer extends StatefulWidget {
  const NumberCompositionTrainer({
    super.key,
    required this.params,
    this.onComplete,
  });

  final Map<String, dynamic> params;
  final VoidCallback? onComplete;

  @override
  State<NumberCompositionTrainer> createState() =>
      _NumberCompositionTrainerState();
}

class _NumberCompositionTrainerState extends State<NumberCompositionTrainer> {
  late final CompositionEquation _equation;
  late final List<int> _digitChoices;

  var _phaseIndex = 0;
  int? _wrongValue;
  int? _selectedValue;
  var _isAdvancing = false;
  var _completeCalled = false;
  Timer? _completeTimer;

  @override
  void initState() {
    super.initState();
    final whole = widget.params['whole'] as int? ?? 2;
    final knownPart = widget.params['knownPart'] as int? ?? 0;
    final answerRangeStart = widget.params['answerRangeStart'] as int? ?? 0;

    _equation = getCompositionEquation(whole, knownPart);
    _digitChoices = getDigitAnswerChoices(answerRangeStart);
  }

  CompositionPhase get _phase =>
      compositionPhases[_phaseIndex.clamp(0, compositionPhases.length - 1)];

  bool get _isLastPhase => _phaseIndex >= compositionPhases.length - 1;

  void _advancePhase() {
    setState(() {
      _isAdvancing = true;
      _wrongValue = null;
      _selectedValue = null;
    });

    Future<void>.delayed(const Duration(milliseconds: _phaseAdvanceMs), () {
      if (!mounted) {
        return;
      }
      setState(() {
        _phaseIndex =
            (_phaseIndex + 1).clamp(0, compositionPhases.length - 1);
        _isAdvancing = false;
      });
    });
  }

  void _handleDemoContinue() {
    if (getNextPhase(_phase) == null) {
      return;
    }
    _advancePhase();
  }

  void _handleAnswer(int value) {
    if (_isAdvancing || !isPracticePhase(_phase)) {
      return;
    }

    if (value == _equation.missingPart) {
      setState(() {
        _wrongValue = null;
        _selectedValue = value;
      });

      if (_isLastPhase) {
        _scheduleComplete();
        return;
      }

      _advancePhase();
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
    final whole = widget.params['whole'] as int? ?? 2;
    final knownPart = widget.params['knownPart'] as int? ?? 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _phasePrompt(_phase, whole, knownPart),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF4B5563),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xB3EEF2FF), Colors.white],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE0E7FF)),
          ),
          child: EquationScene(
            key: ValueKey(_phase),
            equation: _equation,
            mode: _phase,
          ),
        ),
        const SizedBox(height: 20),
        if (isDemoPhase(_phase))
          Center(
            child: FilledButton(
              onPressed: _isAdvancing ? null : _handleDemoContinue,
              child: const Text('Дальше'),
            ),
          ),
        if (_phase == 'practice-dots') ...[
          DotChoiceBar(
            disabled: _isAdvancing || _selectedValue != null,
            onSelect: _handleAnswer,
            selectedValue: _selectedValue,
            wrongValue: _wrongValue,
          ),
        ],
        if (_phase == 'practice-digits')
          NumericChoiceBar(
            choices: _digitChoices,
            disabled: _isAdvancing ||
                (_selectedValue != null && _isLastPhase),
            onSelect: _handleAnswer,
            selectedValue: _selectedValue,
            wrongValue: _wrongValue,
          ),
        if (_isLastPhase && _selectedValue == _equation.missingPart) ...[
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
