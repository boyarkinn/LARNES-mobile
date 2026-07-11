import 'dart:async';

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/reading/letter_marquee_tap/marquee_model.dart';
import 'package:larnes_mobile/trainers/reading/letter_marquee_tap/marquee_progress_dots.dart';
import 'package:larnes_mobile/trainers/reading/letter_marquee_tap/marquee_scene.dart';
import 'package:larnes_mobile/trainers/reading/letter_model.dart';
import 'package:larnes_mobile/trainers/shared/seeded_rng.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';
import 'package:larnes_mobile/trainers/shared/trainer_timings.dart';

/// Web v2: `platform/src/trainers/reading/letter-marquee-tap/component.tsx`
class LetterMarqueeTapTrainer extends StatefulWidget {
  const LetterMarqueeTapTrainer({
    super.key,
    required this.params,
    this.onComplete,
  });

  final Map<String, dynamic> params;
  final VoidCallback? onComplete;

  @override
  State<LetterMarqueeTapTrainer> createState() => _LetterMarqueeTapTrainerState();
}

class _LetterMarqueeTapTrainerState extends State<LetterMarqueeTapTrainer> {
  late final List<String> _practiceLetters;
  late final List<MarqueeTokenSpec> _stream;
  late final int _targetCount;

  var _caughtCount = 0;
  var _isCompleted = false;
  var _completeCalled = false;
  Timer? _completeTimer;

  @override
  void initState() {
    super.initState();
    _targetCount = widget.params['targetCount'] as int? ?? 5;
    final practiceRaw = widget.params['practiceLetters'] as String? ?? 'А';
    _practiceLetters = parsePracticeLetters(practiceRaw);
    _stream = _buildStream(practiceRaw);
  }

  List<MarqueeTokenSpec> _buildStream(String practiceRaw) {
    final letterCase = widget.params['letterCase'] as String? ?? 'upper';
    final speed = widget.params['speed'] as String? ?? 'medium';
    final streamSalt = createLayoutSalt();
    final seed = buildMarqueeStreamSeed([
      _targetCount,
      practiceRaw,
      letterCase,
      speed,
      streamSalt,
    ]);

    return buildMarqueeStream(
      BuildMarqueeStreamInput(
        practiceLetters: _practiceLetters,
        seed: seed,
        targetCount: _targetCount,
      ),
    );
  }

  void _handleCatch() {
    setState(() {
      _caughtCount += 1;
      if (isMarqueeRoundComplete(_caughtCount, _targetCount)) {
        _isCompleted = true;
      }
    });

    if (isMarqueeRoundComplete(_caughtCount, _targetCount)) {
      _scheduleComplete();
    }
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
    final letterCase = widget.params['letterCase'] as String? ?? 'upper';
    final speed = widget.params['speed'] as String? ?? 'medium';

    return TrainerScene(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.96,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MarqueeScene(
                  stream: _stream,
                  letterCase: letterCase,
                  speed: speed,
                  disabled: _isCompleted,
                  onCatch: _handleCatch,
                ),
                MarqueeProgressDots(
                  caughtCount: _caughtCount,
                  targetCount: _targetCount,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
