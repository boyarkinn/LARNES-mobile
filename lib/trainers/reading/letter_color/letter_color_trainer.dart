import 'dart:async';

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/reading/letter_color/color_letter_pad.dart';
import 'package:larnes_mobile/trainers/reading/letter_model.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';
import 'package:larnes_mobile/trainers/shared/trainer_timings.dart';

/// Web v2: `platform/src/trainers/reading/letter-color/component.tsx`
class LetterColorTrainer extends StatefulWidget {
  const LetterColorTrainer({
    super.key,
    required this.params,
    this.onComplete,
  });

  final Map<String, dynamic> params;
  final VoidCallback? onComplete;

  @override
  State<LetterColorTrainer> createState() => _LetterColorTrainerState();
}

class _LetterColorTrainerState extends State<LetterColorTrainer> {
  var _isDone = false;
  var _completeCalled = false;
  Timer? _completeTimer;
  late final String _displayLetter;

  @override
  void initState() {
    super.initState();
    _displayLetter = _buildDisplayLetter();
  }

  String _buildDisplayLetter() {
    final letter =
        normalizeTargetLetter(widget.params['letter'] as String? ?? 'А');
    final letterCase = widget.params['letterCase'] as String? ?? 'upper';
    return applyLetterCase(letter, letterCase);
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
      child: ColorLetterPad(
        disabled: _isDone,
        displayLetter: _displayLetter,
        onDone: _handleDone,
      ),
    );
  }
}
