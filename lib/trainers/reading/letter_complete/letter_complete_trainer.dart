import 'dart:async';

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/reading/letter_complete/complete_model.dart';
import 'package:larnes_mobile/trainers/reading/letter_complete/complete_pad.dart';
import 'package:larnes_mobile/trainers/reading/letter_model.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';
import 'package:larnes_mobile/trainers/shared/trainer_timings.dart';

/// Web v2: `platform/src/trainers/reading/letter-complete/component.tsx`
class LetterCompleteTrainer extends StatefulWidget {
  const LetterCompleteTrainer({
    super.key,
    required this.params,
    this.onComplete,
  });

  final Map<String, dynamic> params;
  final VoidCallback? onComplete;

  @override
  State<LetterCompleteTrainer> createState() => _LetterCompleteTrainerState();
}

class _LetterCompleteTrainerState extends State<LetterCompleteTrainer> {
  late final String _guideLetter;
  late final String _displayLetter;
  late final int _seed;
  late final int _missingSegmentIndex;

  var _completeCalled = false;
  Timer? _completeTimer;

  @override
  void initState() {
    super.initState();
    _initRound();
  }

  void _initRound() {
    _guideLetter =
        normalizeTargetLetter(widget.params['letter'] as String? ?? 'А');
    final letterCase = widget.params['letterCase'] as String? ?? 'upper';
    final missingSegment = widget.params['missingSegment'] ?? 'random';
    _displayLetter = applyLetterCase(_guideLetter, letterCase);
    _seed = buildLetterCompleteRoundSeed([
      _guideLetter,
      letterCase,
      missingSegment,
    ]);
    _missingSegmentIndex = resolveMissingSegmentIndex(
      _guideLetter,
      missingSegment,
      _seed,
    );
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
      child: LetterCompletePad(
        displayLetter: _displayLetter,
        guideLetter: _guideLetter,
        missingSegmentIndex: _missingSegmentIndex,
        onPassed: _handlePassed,
      ),
    );
  }
}
