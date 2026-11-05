import 'dart:async';

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/reading/letter_build/build_scene.dart';
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
  var _completeCalled = false;
  Timer? _completeTimer;

  late String _displayLetter;

  @override
  void initState() {
    super.initState();
    _loadLetterParams();
  }

  void _loadLetterParams() {
    final guideLetter =
        normalizeDrawShowLetter(widget.params['letter'] as String? ?? 'А');
    final letterCase = widget.params['letterCase'] as String? ?? 'upper';
    _displayLetter = applyLetterCase(guideLetter, letterCase);
  }

  @override
  void didUpdateWidget(LetterBuildTrainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.params['letter'] != widget.params['letter'] ||
        oldWidget.params['letterCase'] != widget.params['letterCase']) {
      _completeTimer?.cancel();
      _completeCalled = false;
      _loadLetterParams();
    }
  }

  void _handleGuideComplete() {
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
        displayLetter: _displayLetter,
        guideLetter: _displayLetter,
        onGuideComplete: _handleGuideComplete,
      ),
    );
  }
}
