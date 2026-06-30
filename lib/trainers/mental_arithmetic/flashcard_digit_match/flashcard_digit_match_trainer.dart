import 'dart:async';

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/flashcard_digit_match/flashcard_digit_match_model.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/flashcard_digit_match/match_board.dart';
import 'package:larnes_mobile/trainers/shared/seeded_rng.dart';
import 'package:larnes_mobile/trainers/shared/trainer_timings.dart';

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

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Проведи пальцем линию от абакуса к подходящей цифре',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF4B5563),
          ),
        ),
        const SizedBox(height: 16),
        MatchBoard(
          connections: _connections,
          disabled: _isComplete,
          onConnect: _handleConnect,
          round: _round,
          totalRods: totalRods,
        ),
        const SizedBox(height: 12),
        if (_isComplete)
          const Text(
            'Все пары соединены!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF059669),
            ),
          )
        else
          Text(
            'Соединено ${_connections.length} из ${_values.length}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
            ),
          ),
      ],
    );
  }
}
