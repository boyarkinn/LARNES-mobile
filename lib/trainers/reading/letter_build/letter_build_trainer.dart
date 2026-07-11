import 'dart:async';

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/reading/letter_build/build_scene.dart';
import 'package:larnes_mobile/trainers/reading/letter_build/letter_build_model.dart';
import 'package:larnes_mobile/trainers/reading/letter_model.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';
import 'package:larnes_mobile/trainers/shared/trainer_timings.dart';

/// Web v2: `platform/src/trainers/reading/letter-build/component.tsx`
class LetterBuildTrainer extends StatefulWidget {
  const LetterBuildTrainer({
    super.key,
    required this.params,
    this.onComplete,
  });

  final Map<String, dynamic> params;
  final VoidCallback? onComplete;

  @override
  State<LetterBuildTrainer> createState() => _LetterBuildTrainerState();
}

class _LetterBuildTrainerState extends State<LetterBuildTrainer> {
  var _phase = BuildPhase.guide;
  var _sceneKey = 0;
  var _completeCalled = false;
  Timer? _completeTimer;

  late final String _guideLetter;
  late final String _displayLetter;

  @override
  void initState() {
    super.initState();
    _guideLetter =
        normalizeTargetLetter(widget.params['letter'] as String? ?? 'А');
    final letterCase = widget.params['letterCase'] as String? ?? 'upper';
    _displayLetter = applyLetterCase(_guideLetter, letterCase);
  }

  void _handleGuideComplete() {
    setState(() {
      _phase = BuildPhase.free;
      _sceneKey += 1;
    });
  }

  void _handleFreePassed(int _) {
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
      child: BuildScene(
        key: ValueKey(_sceneKey),
        displayLetter: _displayLetter,
        guideLetter: _guideLetter,
        onFreePassed: _handleFreePassed,
        onGuideComplete: _handleGuideComplete,
        phase: _phase,
      ),
    );
  }
}
