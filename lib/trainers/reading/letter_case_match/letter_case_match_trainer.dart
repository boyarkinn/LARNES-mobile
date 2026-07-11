import 'dart:async';

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/reading/letter_colors.dart';
import 'package:larnes_mobile/trainers/reading/letter_case_match/case_match_model.dart';
import 'package:larnes_mobile/trainers/reading/letter_case_match/case_match_scene.dart';
import 'package:larnes_mobile/trainers/reading/letter_model.dart';
import 'package:larnes_mobile/trainers/shared/seeded_rng.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';
import 'package:larnes_mobile/trainers/shared/trainer_timings.dart';

/// Web v2: `platform/src/trainers/reading/letter-case-match/component.tsx`
class LetterCaseMatchTrainer extends StatefulWidget {
  const LetterCaseMatchTrainer({
    super.key,
    required this.params,
    this.onComplete,
  });

  final Map<String, dynamic> params;
  final VoidCallback? onComplete;

  @override
  State<LetterCaseMatchTrainer> createState() => _LetterCaseMatchTrainerState();
}

class _LetterCaseMatchTrainerState extends State<LetterCaseMatchTrainer> {
  late final int _layoutSalt;
  late final List<String> _practiceLetters;
  late final int _seed;
  late final List<String> _selectedLetters;
  late final LetterMatchRound _round;
  late final Map<String, String> _colorByLeftId;

  final _connections = <LetterMatchConnection>[];
  var _isCompleted = false;
  var _completeCalled = false;
  Timer? _completeTimer;

  @override
  void initState() {
    super.initState();
    _layoutSalt = createLayoutSalt();
    _practiceLetters = parsePracticeLetters(
      widget.params['practiceLetters'] as String? ?? 'А',
    );
    _seed = buildCaseMatchRoundSeed([
      widget.params['pairCount'] ?? 3,
      widget.params['practiceLetters'] ?? 'А',
      _layoutSalt,
    ]);
    _selectedLetters = buildSelectedLetters(
      pairCount: widget.params['pairCount'] as int? ?? 3,
      practiceLetters: _practiceLetters,
      seed: _seed,
    );
    _round = buildLetterMatchRound(_selectedLetters, _seed);
    _colorByLeftId = {
      for (var index = 0; index < _round.leftItems.length; index++)
        _round.leftItems[index].id: pickLetterDisplayColor(
          createSeededRng(_seed + 31 + index),
        ),
    };
  }

  void _handleConnect(LetterMatchConnection connection) {
    if (_connections.any((item) => item.leftId == connection.leftId)) {
      return;
    }

    setState(() {
      _connections.add(connection);

      if (isCaseMatchRoundComplete(_connections, _selectedLetters)) {
        _isCompleted = true;
        _scheduleComplete();
      }
    });
  }

  void _scheduleComplete() {
    if (_completeCalled || widget.onComplete == null) {
      return;
    }

    _completeCalled = true;
    _completeTimer = Timer(
      const Duration(milliseconds: TrainerTimings.completeDelayMs),
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
      child: CaseMatchScene(
        colorByLeftId: _colorByLeftId,
        connections: _connections,
        disabled: _isCompleted,
        onConnect: _handleConnect,
        round: _round,
      ),
    );
  }
}
