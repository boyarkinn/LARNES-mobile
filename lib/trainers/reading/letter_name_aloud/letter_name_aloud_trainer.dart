import 'dart:async';

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/reading/letter_colors.dart';
import 'package:larnes_mobile/trainers/reading/letter_find_tap/letter_field_scene.dart';
import 'package:larnes_mobile/trainers/reading/letter_name_aloud/name_aloud_dots.dart';
import 'package:larnes_mobile/trainers/reading/letter_name_aloud/name_aloud_model.dart';
import 'package:larnes_mobile/trainers/reading/letter_name_aloud/name_aloud_scene.dart';
import 'package:larnes_mobile/trainers/reading/letter_name_aloud/name_aloud_sizes.dart';
import 'package:larnes_mobile/trainers/shared/seeded_rng.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';

/// Web v2: `platform/src/trainers/reading/letter-name-aloud/component.tsx`
class LetterNameAloudTrainer extends StatefulWidget {
  const LetterNameAloudTrainer({
    super.key,
    required this.params,
    this.onComplete,
  });

  final Map<String, dynamic> params;
  final VoidCallback? onComplete;

  @override
  State<LetterNameAloudTrainer> createState() => _LetterNameAloudTrainerState();
}

class _LetterNameAloudTrainerState extends State<LetterNameAloudTrainer> {
  late final List<String> _letters;
  late final List<Color> _letterColors;
  late final int _displayMs;

  var _index = 0;
  var _isFinished = false;
  var _completeCalled = false;
  Timer? _slideTimer;
  Timer? _completeTimer;

  @override
  void initState() {
    super.initState();
    _initRound();
    _scheduleSlide();
  }

  void _initRound() {
    final practiceLetters = widget.params['practiceLetters'] as String? ?? 'А';
    final letterCase = widget.params['letterCase'] as String? ?? 'upper';
    final displaySeconds = widget.params['displaySeconds'] as int? ?? 3;

    _letters = buildDisplayLetters(practiceLetters, letterCase);
    _displayMs = displaySeconds * 1000;

    final colorRng = createSeededRng(
      hashParamsSeed([practiceLetters, letterCase, 'name-aloud-colors']),
    );
    _letterColors = [
      for (var index = 0; index < _letters.length; index++)
        letterDisplayColorFromHex(pickLetterDisplayColor(colorRng)),
    ];
  }

  void _resetRound() {
    _slideTimer?.cancel();
    _completeTimer?.cancel();
    setState(() {
      _index = 0;
      _isFinished = false;
      _completeCalled = false;
    });
    _scheduleSlide();
  }

  void _scheduleSlide() {
    _slideTimer?.cancel();

    if (_isFinished || _letters.isEmpty) {
      return;
    }

    _slideTimer = Timer(Duration(milliseconds: _displayMs), () {
      if (!mounted) {
        return;
      }

      if (_index >= _letters.length - 1) {
        setState(() => _isFinished = true);
        _scheduleComplete();
        return;
      }

      setState(() => _index++);
      _scheduleSlide();
    });
  }

  void _scheduleComplete() {
    if (_completeCalled || widget.onComplete == null) {
      return;
    }

    _completeCalled = true;
    _slideTimer?.cancel();
    _completeTimer = Timer(
      const Duration(milliseconds: nameAloudFinishDelayMs),
      () {
        if (mounted) {
          widget.onComplete?.call();
        }
      },
    );
  }

  @override
  void didUpdateWidget(LetterNameAloudTrainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.params['practiceLetters'] != widget.params['practiceLetters'] ||
        oldWidget.params['letterCase'] != widget.params['letterCase'] ||
        oldWidget.params['displaySeconds'] != widget.params['displaySeconds']) {
      _initRound();
      _resetRound();
    }
  }

  @override
  void dispose() {
    _slideTimer?.cancel();
    _completeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_letters.isEmpty) {
      return const SizedBox.shrink();
    }

    final displayIndex = _isFinished ? _letters.length - 1 : _index;
    final currentLetter = _letters[displayIndex];
    final currentLetterColor = _letterColors[displayIndex];
    final completedCount = _isFinished ? _letters.length : _index;
    final activeIndex = _isFinished ? _letters.length - 1 : _index;

    return TrainerSceneColumn(
      body: NameAloudScene(
        displayPulseActive: !_isFinished,
        letter: currentLetter,
        letterColor: currentLetterColor,
        letterKey: '$currentLetter-$displayIndex',
        settlePulseActive: _isFinished,
      ),
      footer: NameAloudDots(
        activeColor: currentLetterColor,
        activeIndex: activeIndex,
        completedCount: completedCount,
        totalCount: _letters.length,
      ),
    );
  }
}
