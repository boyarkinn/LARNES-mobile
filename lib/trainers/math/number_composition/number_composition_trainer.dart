import 'dart:async';

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/math/number_composition/composition_reveal.dart';
import 'package:larnes_mobile/trainers/math/number_composition/composition_scene_layout.dart';
import 'package:larnes_mobile/trainers/math/number_composition/digit_choice_bar.dart';
import 'package:larnes_mobile/trainers/math/number_composition/dot_choice_bar.dart';
import 'package:larnes_mobile/trainers/math/number_composition/equation_scene.dart';
import 'package:larnes_mobile/trainers/math/number_composition/missing_slot.dart';
import 'package:larnes_mobile/trainers/math/number_composition/number_composition_model.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';
import 'package:larnes_mobile/trainers/shared/trainer_timings.dart';

/// Web v2: `platform/src/trainers/math/number-composition/component.tsx`
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

  final GlobalKey<MissingSlotState> _slotKey = GlobalKey<MissingSlotState>();

  var _phaseIndex = 0;
  int? _wrongValue;
  int? _selectedValue;
  var _isAdvancing = false;
  var _isRevealComplete = false;
  var _completeCalled = false;
  Timer? _demoTimer;
  Timer? _revealTimer;
  Timer? _phaseAdvanceTimer;
  Timer? _wrongFeedbackTimer;
  Timer? _completeTimer;

  @override
  void initState() {
    super.initState();
    final whole = widget.params['whole'] as int? ?? 2;
    final knownPart = widget.params['knownPart'] as int? ?? 0;
    final answerRangeStart = widget.params['answerRangeStart'] as int? ?? 0;

    _equation = getCompositionEquation(whole, knownPart);
    _digitChoices = getDigitAnswerChoices(answerRangeStart);
    _onPhaseChanged();
  }

  CompositionPhase get _phase =>
      compositionPhases[_phaseIndex.clamp(0, compositionPhases.length - 1)];

  bool get _isLastPhase => _phaseIndex >= compositionPhases.length - 1;

  bool get _practiceLocked =>
      _isAdvancing ||
      !_isRevealComplete ||
      (_selectedValue != null && _isLastPhase);

  void _onPhaseChanged() {
    _demoTimer?.cancel();
    _revealTimer?.cancel();

    if (isDemoPhase(_phase)) {
      setState(() => _isRevealComplete = true);
      _scheduleDemoAuto();
      return;
    }

    _schedulePracticeReveal();
  }

  void _scheduleDemoAuto() {
    if (!isDemoPhase(_phase) || _isAdvancing) {
      return;
    }

    _demoTimer = Timer(
      Duration(milliseconds: getDemoPhaseDurationMs()),
      () {
        if (!mounted || !isDemoPhase(_phase) || _isAdvancing) {
          return;
        }
        _advancePhase();
      },
    );
  }

  void _schedulePracticeReveal() {
    setState(() => _isRevealComplete = false);

    _revealTimer = Timer(
      Duration(milliseconds: getPracticeInteractionReadyMs(4)),
      () {
        if (!mounted) {
          return;
        }
        setState(() => _isRevealComplete = true);
      },
    );
  }

  void _advancePhase() {
    _demoTimer?.cancel();
    _phaseAdvanceTimer?.cancel();
    setState(() {
      _isAdvancing = true;
      _wrongValue = null;
      _selectedValue = null;
    });

    _phaseAdvanceTimer = Timer(
      const Duration(milliseconds: TrainerTimings.phaseAdvanceMs),
      () {
        if (!mounted) {
          return;
        }
        setState(() {
          _phaseIndex =
              (_phaseIndex + 1).clamp(0, compositionPhases.length - 1);
          _isAdvancing = false;
        });
        _onPhaseChanged();
      },
    );
  }

  void _handleDemoTap() {
    if (!isDemoPhase(_phase) || _isAdvancing) {
      return;
    }
    _advancePhase();
  }

  void _handleAnswer(int value) {
    if (_isAdvancing || !isPracticePhase(_phase) || !_isRevealComplete) {
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

      _phaseAdvanceTimer?.cancel();
      _phaseAdvanceTimer = Timer(
        const Duration(milliseconds: TrainerTimings.phaseAdvanceMs),
        () {
          if (mounted) {
            _advancePhase();
          }
        },
      );
      return;
    }

    _wrongFeedbackTimer?.cancel();
    setState(() => _wrongValue = value);
    _wrongFeedbackTimer = Timer(
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
    _demoTimer?.cancel();
    _revealTimer?.cancel();
    _phaseAdvanceTimer?.cancel();
    _wrongFeedbackTimer?.cancel();
    _completeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TrainerScene(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final viewportWidth = constraints.maxWidth;
          final viewportHeight = constraints.maxHeight;
          final showDigits = _phase == 'practice-digits';
          final choiceLayout = computeCompositionChoiceBarLayout(
            viewportWidth: viewportWidth,
            viewportHeight: viewportHeight,
            showDigits: showDigits,
          );

          final equation = EquationScene(
            key: ValueKey(_phase),
            acceptSlotDrops: isPracticePhase(_phase) && !_practiceLocked,
            equation: _equation,
            isSlotShaking: _wrongValue != null,
            mode: _phase,
            onSlotAccept: _handleAnswer,
            selectedValue: _selectedValue,
            slotKey: _slotKey,
          );

          if (isPracticePhase(_phase)) {
            return Column(
              key: ValueKey('practice-$_phase'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Center(child: equation),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    choiceLayout.horizontalPadding,
                    choiceLayout.paddingTop,
                    choiceLayout.horizontalPadding,
                    choiceLayout.paddingBottom,
                  ),
                  child: _phase == 'practice-dots'
                      ? DotChoiceBar(
                          buttonHeight: choiceLayout.buttonHeight,
                          disabled: _practiceLocked,
                          dotChoiceSize: choiceLayout.dotChoiceSize,
                          onSelect: _handleAnswer,
                          selectedValue: _selectedValue,
                          wrongValue: _wrongValue,
                        )
                      : DigitChoiceBar(
                          buttonHeight: choiceLayout.buttonHeight,
                          choices: _digitChoices,
                          disabled: _practiceLocked,
                          fontSize: choiceLayout.fontSize,
                          onSelect: _handleAnswer,
                          selectedValue: _selectedValue,
                          wrongValue: _wrongValue,
                        ),
                ),
              ],
            );
          }

          return GestureDetector(
            key: ValueKey('demo-$_phase'),
            behavior: HitTestBehavior.opaque,
            onTap: _handleDemoTap,
            child: Center(child: equation),
          );
        },
      ),
    );
  }
}
