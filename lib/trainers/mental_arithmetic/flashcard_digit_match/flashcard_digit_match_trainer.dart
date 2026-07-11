import 'dart:async';

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/flashcard_digit_match/flashcard_digit_match_model.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/flashcard_digit_match/match_board.dart';
import 'package:larnes_mobile/trainers/shared/seeded_rng.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';
import 'package:larnes_mobile/trainers/shared/trainer_timings.dart';

/// Web v2: `platform/src/trainers/mental-arithmetic/flashcard-digit-match/component.tsx`
class FlashcardDigitMatchTrainer extends StatefulWidget {
  const FlashcardDigitMatchTrainer({
    super.key,
    required this.params,
    this.onComplete,
  });

  final Map<String, dynamic> params;
  final VoidCallback? onComplete;

  @override
  State<FlashcardDigitMatchTrainer> createState() =>
      _FlashcardDigitMatchTrainerState();
}

class _FlashcardDigitMatchTrainerState extends State<FlashcardDigitMatchTrainer> {
  late final MatchRound _round;
  late final List<int> _values;
  final List<MatchConnection> _connections = [];
  var _isComplete = false;
  var _completeCalled = false;
  Timer? _completeTimer;

  @override
  void initState() {
    super.initState();
    _values = List<int>.from(widget.params['values'] as List? ?? const []);
    final totalRods = widget.params['totalRods'] as int? ?? 1;
    final seed = hashParamsSeed([..._values, totalRods]);
    _round = buildMatchRound(_values, seed);
  }

  void _handleConnect(MatchConnection connection) {
    if (_connections.any((item) => item.leftId == connection.leftId)) {
      return;
    }

    setState(() => _connections.add(connection));

    if (isRoundComplete(_connections, _values)) {
      setState(() => _isComplete = true);
      _scheduleComplete();
    }
  }

  void _scheduleComplete() {
    if (_completeCalled || widget.onComplete == null) {
      return;
    }

    _completeCalled = true;
    _completeTimer = Timer(
      const Duration(milliseconds: TrainerTimings.flashcardCompleteDelayMs),
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
    final totalRods = widget.params['totalRods'] as int? ?? 1;

    return TrainerScene(
      child: MatchBoard(
        connections: _connections,
        disabled: _isComplete,
        onConnect: _handleConnect,
        round: _round,
        totalRods: totalRods,
      ),
    );
  }
}
