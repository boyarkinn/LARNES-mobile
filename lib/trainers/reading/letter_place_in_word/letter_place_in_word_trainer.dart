import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/reading/letter_colors.dart';
import 'package:larnes_mobile/trainers/reading/letter_model.dart';
import 'package:larnes_mobile/trainers/reading/letter_place_in_word/fill_gap_scene.dart';
import 'package:larnes_mobile/trainers/reading/letter_place_in_word/place_in_word_model.dart';
import 'package:larnes_mobile/trainers/shared/seeded_rng.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';

/// Web v2: `platform/src/trainers/reading/letter-place-in-word/component.tsx`
class LetterPlaceInWordTrainer extends StatefulWidget {
  const LetterPlaceInWordTrainer({
    super.key,
    required this.params,
    this.onComplete,
  });

  final Map<String, dynamic> params;
  final VoidCallback? onComplete;

  @override
  State<LetterPlaceInWordTrainer> createState() => _LetterPlaceInWordTrainerState();
}

class _LetterPlaceInWordTrainerState extends State<LetterPlaceInWordTrainer> {
  late final int _layoutSalt;
  late final List<String> _practiceLetters;
  late final int _seed;
  late final List<FillGapTask> _tasks;
  late final List<LetterPoolTile> _poolTiles;
  late final Map<String, String> _tileColors;

  @override
  void initState() {
    super.initState();
    _layoutSalt = createLayoutSalt();
    _practiceLetters = parsePracticeLetters(
      widget.params['practiceLetters'] as String? ?? 'А',
    );
    final entityCount = widget.params['entityCount'] as int? ?? 1;
    final distractorCount = widget.params['distractorCount'] as int? ?? 3;
    final letterCase = widget.params['letterCase'] as String? ?? 'upper';
    final wordCase = widget.params['wordCase'] as String? ?? 'upper';

    _seed = buildPlaceInWordRoundSeed([
      entityCount,
      widget.params['practiceLetters'] ?? 'А',
      distractorCount,
      wordCase,
      letterCase,
      _layoutSalt,
    ]);
    _tasks = buildFillGapTasks(
      entityCount: entityCount,
      letterCase: letterCase,
      practiceLetters: _practiceLetters,
      seed: _seed,
      wordCase: wordCase,
    );
    final poolRng = createSeededRng(_seed + 17);
    _poolTiles = buildLetterPoolTiles(
      distractorCount: distractorCount,
      letterCase: letterCase,
      rng: poolRng,
      tasks: _tasks,
    );
    _tileColors = {
      for (final tile in _poolTiles) tile.id: pickLetterDisplayColor(poolRng),
    };
  }

  @override
  Widget build(BuildContext context) {
    return TrainerScene(
      child: FillGapScene(
        onComplete: () => widget.onComplete?.call(),
        poolTiles: _poolTiles,
        tasks: _tasks,
        tileColors: _tileColors,
      ),
    );
  }
}
