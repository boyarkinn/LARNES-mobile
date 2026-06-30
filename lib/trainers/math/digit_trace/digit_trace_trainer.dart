import 'dart:async';

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/math/digit_trace/trace_pad.dart';
import 'package:larnes_mobile/trainers/shared/trainer_timings.dart';

class DigitTraceTrainer extends StatefulWidget {
  const DigitTraceTrainer({
    super.key,
    required this.params,
    this.onComplete,
  });

  final Map<String, dynamic> params;
  final VoidCallback? onComplete;

  @override
  State<DigitTraceTrainer> createState() => _DigitTraceTrainerState();
}

class _DigitTraceTrainerState extends State<DigitTraceTrainer> {
  var _completeCalled = false;
  Timer? _completeTimer;

  void _handleScored(int _) {
    _scheduleComplete();
  }

  void _scheduleComplete() {
    if (_completeCalled || widget.onComplete == null) {
      return;
    }

    _completeCalled = true;
    _completeTimer = Timer(
      const Duration(milliseconds: TrainerTimings.traceCompleteDelayMs),
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
    final digit = widget.params['digit'] as int? ?? 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Обведи цифру $digit пальцем по пунктиру — покажем, насколько получилось похоже',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF4B5563),
          ),
        ),
        const SizedBox(height: 20),
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE0E7FF)),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xB3EEF2FF),
                Colors.white,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
            child: TracePad(
              digit: digit,
              onScored: _handleScored,
            ),
          ),
        ),
      ],
    );
  }
}
