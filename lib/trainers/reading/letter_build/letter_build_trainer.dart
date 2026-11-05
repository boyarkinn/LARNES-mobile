import 'dart:async';

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/audio/speech_bank.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/audio/clip_player.dart';
import 'package:larnes_mobile/trainers/reading/letter_build/build_scene.dart';
import 'package:larnes_mobile/trainers/reading/letter_model.dart';
import 'package:larnes_mobile/trainers/shared/letters_syllables/resolve_letter_syllable_audio.dart';
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
  var _completionRun = 0;
  ClipPlayer? _completionPlayer;
  int? _audioGeneration;

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
      _cancelCompletion();
      _completeCalled = false;
      _loadLetterParams();
    }
  }

  void _handleGuideComplete() async {
    if (_completeCalled) {
      return;
    }

    _completeCalled = true;
    final run = ++_completionRun;
    final key = letterSyllableAudioKey(_displayLetter);
    final file = key == null ? null : speechAudioFile(key);
    final waits = <Future<void>>[
      Future<void>.delayed(const Duration(
        milliseconds: TrainerTimings.completeAfterBurstMs,
      )),
    ];
    if (file != null) {
      final player = getSharedClipPlayer();
      _completionPlayer = player;
      final playback = player.play([file.path], playbackRate: 1);
      _audioGeneration = player.generation;
      waits.add(playback
          .timeout(Duration(
            milliseconds: (file.durationMs + 5000).clamp(6000, 18000).toInt(),
          ))
          .catchError((Object _) {
            if (player.generation == _audioGeneration) {
              unawaited(player.cancel());
            }
          }));
    }
    await Future.wait(waits);
    if (!mounted || run != _completionRun) {
      return;
    }
    _completionPlayer = null;
    _audioGeneration = null;
    widget.onComplete?.call();
  }

  void _cancelCompletion() {
    _completionRun++;
    final player = _completionPlayer;
    if (player != null && player.generation == _audioGeneration) {
      unawaited(player.cancel());
    }
    _completionPlayer = null;
    _audioGeneration = null;
  }

  @override
  void dispose() {
    _cancelCompletion();
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
