import 'dart:async';

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/reading/letter_colors.dart';
import 'package:larnes_mobile/trainers/reading/letter_model.dart';
import 'package:larnes_mobile/trainers/reading/letter_trace/letter_trace_pad.dart';
import 'package:larnes_mobile/trainers/shared/seeded_rng.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';
import 'package:larnes_mobile/trainers/shared/trainer_timings.dart';

/// Web v2: `platform/src/trainers/reading/letter-trace/component.tsx`
class LetterTraceTrainer extends StatefulWidget {
  const LetterTraceTrainer({
    super.key,
    required this.params,
    this.onComplete,
  });

  final Map<String, dynamic> params;
  final VoidCallback? onComplete;

  @override
  State<LetterTraceTrainer> createState() => _LetterTraceTrainerState();
}

class _LetterTraceTrainerState extends State<LetterTraceTrainer> {
  var _completeCalled = false;
  Timer? _completeTimer;
  late final String _guideLetter;
  late final String _displayLetter;
  late final String _displayColor;

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
    final seed = hashParamsSeed([_guideLetter, letterCase, 'letter-trace']);
    _displayColor = pickLetterDisplayColor(createSeededRng(seed));
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
  void dispose() {
    _completeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TrainerScene(
      child: LetterTracePad(
        displayColor: _displayColor,
        displayLetter: _displayLetter,
        guideLetter: _guideLetter,
        onPassed: _handlePassed,
      ),
    );
  }
}
