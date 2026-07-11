import 'dart:async';

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/reading/letter_half_draw/half_draw_pad.dart';
import 'package:larnes_mobile/trainers/reading/letter_model.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';
import 'package:larnes_mobile/trainers/shared/trainer_timings.dart';

/// Web v2: `platform/src/trainers/reading/letter-half-draw/component.tsx`
class LetterHalfDrawTrainer extends StatefulWidget {
  const LetterHalfDrawTrainer({
    super.key,
    required this.params,
    this.onComplete,
  });

  final Map<String, dynamic> params;
  final VoidCallback? onComplete;

  @override
  State<LetterHalfDrawTrainer> createState() => _LetterHalfDrawTrainerState();
}

class _LetterHalfDrawTrainerState extends State<LetterHalfDrawTrainer> {
  var _completeCalled = false;
  Timer? _completeTimer;

  late String _guideLetter;
  late String _displayLetter;

  @override
  void initState() {
    super.initState();
    _initRound();
  }

  void _initRound() {
    _guideLetter =
        normalizeTargetLetter(widget.params['letter'] as String? ?? 'А');
    final letterCase = widget.params['letterCase'] as String? ?? 'upper';
    _displayLetter = applyLetterCase(_guideLetter, letterCase);
  }

  void _handlePassed(int _) {
    _scheduleComplete();
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
  void didUpdateWidget(LetterHalfDrawTrainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.params['letter'] != widget.params['letter'] ||
        oldWidget.params['letterCase'] != widget.params['letterCase']) {
      _completeTimer?.cancel();
      _completeCalled = false;
      _initRound();
    }
  }

  @override
  void dispose() {
    _completeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TrainerScene(
      child: HalfDrawPad(
        displayLetter: _displayLetter,
        guideLetter: _guideLetter,
        onPassed: _handlePassed,
      ),
    );
  }
}
