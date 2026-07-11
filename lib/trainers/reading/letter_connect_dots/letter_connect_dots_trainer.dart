import 'dart:async';

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/reading/letter_colors.dart';
import 'package:larnes_mobile/trainers/reading/letter_connect_dots/connect_dots_scene.dart';
import 'package:larnes_mobile/trainers/reading/letter_find_tap/letter_field_scene.dart';
import 'package:larnes_mobile/trainers/reading/letter_model.dart';
import 'package:larnes_mobile/trainers/shared/seeded_rng.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';
import 'package:larnes_mobile/trainers/shared/trainer_timings.dart';

/// Web v2: `platform/src/trainers/reading/letter-connect-dots/component.tsx`
class LetterConnectDotsTrainer extends StatefulWidget {
  const LetterConnectDotsTrainer({
    super.key,
    required this.params,
    this.onComplete,
  });

  final Map<String, dynamic> params;
  final VoidCallback? onComplete;

  @override
  State<LetterConnectDotsTrainer> createState() =>
      _LetterConnectDotsTrainerState();
}

class _LetterConnectDotsTrainerState extends State<LetterConnectDotsTrainer> {
  var _isCompleted = false;
  var _completeCalled = false;
  Timer? _completeTimer;

  late String _guideLetter;
  late String _dotMode;
  late Color _dotColor;

  @override
  void initState() {
    super.initState();
    _initRound();
  }

  void _initRound() {
    _guideLetter =
        normalizeTargetLetter(widget.params['letter'] as String? ?? 'А');
    final letterCase = widget.params['letterCase'] as String? ?? 'upper';
    _dotMode = widget.params['dotMode'] as String? ?? 'free';
    final seed = hashParamsSeed([
      _guideLetter,
      letterCase,
      _dotMode,
      'letter-connect-dots',
    ]);
    _dotColor = letterDisplayColorFromHex(
      pickLetterDisplayColor(createSeededRng(seed)),
    );
  }

  void _handleSceneComplete() {
    if (_isCompleted) {
      return;
    }

    setState(() => _isCompleted = true);
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
  void didUpdateWidget(LetterConnectDotsTrainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.params['letter'] != widget.params['letter'] ||
        oldWidget.params['letterCase'] != widget.params['letterCase'] ||
        oldWidget.params['dotMode'] != widget.params['dotMode']) {
      _completeTimer?.cancel();
      _isCompleted = false;
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
      child: ConnectDotsScene(
        disabled: _isCompleted,
        dotColor: _dotColor,
        dotMode: _dotMode,
        guideLetter: _guideLetter,
        onComplete: _handleSceneComplete,
      ),
    );
  }
}
