import 'dart:async';

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/reading/letter_case_color/case_color_scene.dart';
import 'package:larnes_mobile/trainers/reading/letter_case_color/letter_case_color_model.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';
import 'package:larnes_mobile/trainers/shared/trainer_timings.dart';

/// Web v2: `platform/src/trainers/reading/letter-case-color/component.tsx`
class LetterCaseColorTrainer extends StatefulWidget {
  const LetterCaseColorTrainer({
    super.key,
    required this.params,
    this.onComplete,
  });

  final Map<String, dynamic> params;
  final VoidCallback? onComplete;

  @override
  State<LetterCaseColorTrainer> createState() => _LetterCaseColorTrainerState();
}

class _LetterCaseColorTrainerState extends State<LetterCaseColorTrainer> {
  var _isDone = false;
  var _completeCalled = false;
  Timer? _completeTimer;
  late final DisplayCasePair _casePair;

  @override
  void initState() {
    super.initState();
    _casePair = getDisplayCasePair(
      widget.params['letter'] as String? ?? 'А',
    );
  }

  void _handleDone() {
    setState(() => _isDone = true);
    _scheduleComplete();
  }

  void _scheduleComplete() {
    if (_completeCalled || widget.onComplete == null) {
      return;
    }

    _completeCalled = true;
    _completeTimer = Timer(
      const Duration(milliseconds: TrainerTimings.colorCompleteDelayMs),
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
    return TrainerScene(
      child: CaseColorScene(
        disabled: _isDone,
        lowerLetter: _casePair.lower,
        onDone: _handleDone,
        upperLetter: _casePair.upper,
      ),
    );
  }
}
