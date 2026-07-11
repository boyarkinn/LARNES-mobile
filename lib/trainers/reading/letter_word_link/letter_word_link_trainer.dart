import 'dart:async';

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/reading/letter_colors.dart';
import 'package:larnes_mobile/trainers/reading/letter_find_tap/letter_field_scene.dart';
import 'package:larnes_mobile/trainers/reading/letter_word_link/word_link_model.dart';
import 'package:larnes_mobile/trainers/reading/letter_word_link/word_link_scene.dart';
import 'package:larnes_mobile/trainers/shared/seeded_rng.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';
import 'package:larnes_mobile/trainers/shared/trainer_timings.dart';

/// Web v2: `platform/src/trainers/reading/letter-word-link/component.tsx`
class LetterWordLinkTrainer extends StatefulWidget {
  const LetterWordLinkTrainer({
    super.key,
    required this.params,
    this.onComplete,
  });

  final Map<String, dynamic> params;
  final VoidCallback? onComplete;

  @override
  State<LetterWordLinkTrainer> createState() => _LetterWordLinkTrainerState();
}

class _LetterWordLinkTrainerState extends State<LetterWordLinkTrainer> {
  late final int _layoutSalt;
  late final int _seed;
  late final WordLinkRound _round;
  late final Color _letterColor;

  final _connections = <WordLinkConnection>[];
  var _isCompleted = false;
  var _completeCalled = false;
  Timer? _completeTimer;

  @override
  void initState() {
    super.initState();
    _layoutSalt = createLayoutSalt();
    _seed = buildWordLinkRoundSeed([
      widget.params['entityCount'] ?? 4,
      widget.params['letter'] ?? 'А',
      widget.params['letterCase'] ?? 'upper',
      widget.params['wordCase'] ?? 'upper',
      _layoutSalt,
    ]);
    _round = buildWordLinkRound(
      BuildWordLinkRoundInput(
        entityCount: widget.params['entityCount'] as int? ?? 4,
        letter: widget.params['letter'] as String? ?? 'А',
        letterCase: widget.params['letterCase'] as String? ?? 'upper',
        seed: _seed,
        wordCase: widget.params['wordCase'] as String? ?? 'upper',
      ),
    );
    _letterColor = letterDisplayColorFromHex(
      pickLetterDisplayColor(createSeededRng(_seed + 9)),
    );
  }

  void _handleConnect(WordLinkConnection connection) {
    if (_connections.any((item) => item.rightId == connection.rightId)) {
      return;
    }

    setState(() {
      _connections.add(connection);

      if (isWordLinkRoundComplete(_connections, _round)) {
        _isCompleted = true;
        _scheduleComplete();
      }
    });
  }

  void _handlePlayWord(WordLinkItem item) {
    if (_isCompleted) {
      return;
    }

    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(
      SnackBar(
        content: Text(getWordLinkAudioStubMessage(item.displayLabel)),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
      child: WordLinkScene(
        connections: _connections,
        disabled: _isCompleted,
        letterColor: _letterColor,
        onConnect: _handleConnect,
        onPlayWord: _handlePlayWord,
        round: _round,
      ),
    );
  }
}
