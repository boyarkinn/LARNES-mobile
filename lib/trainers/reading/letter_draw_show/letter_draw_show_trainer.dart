import 'dart:async';

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/reading/letter_draw_show/draw_round_dots.dart';
import 'package:larnes_mobile/trainers/reading/letter_draw_show/draw_scene.dart';
import 'package:larnes_mobile/trainers/reading/letter_draw_show/draw_show_model.dart';
import 'package:larnes_mobile/trainers/reading/letter_draw_show/draw_show_sizes.dart';
import 'package:larnes_mobile/trainers/reading/letter_model.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';

/// Web v2: `platform/src/trainers/reading/letter-draw-show/component.tsx`
class LetterDrawShowTrainer extends StatefulWidget {
  const LetterDrawShowTrainer({
    super.key,
    required this.params,
    this.onComplete,
  });

  final Map<String, dynamic> params;
  final VoidCallback? onComplete;

  @override
  State<LetterDrawShowTrainer> createState() => _LetterDrawShowTrainerState();
}

class _LetterDrawShowTrainerState extends State<LetterDrawShowTrainer> {
  var _roundIndex = 0;
  var _sceneKey = 0;
  var _isFinished = false;
  var _completeCalled = false;

  Timer? _completeTimer;

  String get _letter => widget.params['letter'] as String? ?? 'А';

  String get _letterCase => widget.params['letterCase'] as String? ?? 'upper';

  int get _totalRounds =>
      normalizeDrawShowRounds(widget.params['rounds'] as int? ?? defaultDrawShowRounds);

  @override
  void initState() {
    super.initState();
    _resetRound();
  }

  void _resetRound() {
    _completeTimer?.cancel();
    setState(() {
      _roundIndex = 0;
      _sceneKey = 0;
      _isFinished = false;
      _completeCalled = false;
    });
  }

  void _handleRoundComplete() {
    if (_roundIndex + 1 >= _totalRounds) {
      setState(() => _isFinished = true);
      _scheduleComplete();
      return;
    }

    setState(() {
      _roundIndex += 1;
      _sceneKey += 1;
    });
  }

  void _scheduleComplete() {
    if (_completeCalled || widget.onComplete == null) {
      return;
    }

    _completeCalled = true;
    _completeTimer = Timer(
      const Duration(milliseconds: drawFinishDelayMs),
      () {
        if (mounted) {
          widget.onComplete?.call();
        }
      },
    );
  }

  @override
  void didUpdateWidget(LetterDrawShowTrainer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.params['letter'] != widget.params['letter'] ||
        oldWidget.params['letterCase'] != widget.params['letterCase'] ||
        oldWidget.params['rounds'] != widget.params['rounds']) {
      _resetRound();
    }
  }

  @override
  void dispose() {
    _completeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final drawing = getZaitsevLetterDrawing(_letter);
    final displayLetter = applyLetterCase(_letter, _letterCase);
    final completedRounds = _isFinished ? _totalRounds : _roundIndex;

    if (drawing == null) {
      return TrainerScene(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Графический образ для буквы «$displayLetter» не найден.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF475569),
              ),
            ),
          ),
        ),
      );
    }

    return TrainerScene(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DrawScene(
              key: ValueKey(_sceneKey),
              drawing: drawing,
              onRoundComplete: _handleRoundComplete,
              settlePulseActive: _isFinished,
            ),
            DrawRoundDots(
              completedRounds: completedRounds,
              totalRounds: _totalRounds,
            ),
          ],
        ),
      ),
    );
  }
}
