import 'dart:async';

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/math/digit_trace/trace_pad.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';
import 'package:larnes_mobile/trainers/shared/trainer_timings.dart';

/// Web v2: `platform/src/trainers/math/digit-trace/component.tsx`
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
    final digit = widget.params['digit'] as int? ?? 0;

    return TrainerScene(
      child: TracePad(
        digit: digit,
        onPassed: _handlePassed,
      ),
    );
  }
}
