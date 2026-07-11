import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/reading/letter_colors.dart';
import 'package:larnes_mobile/trainers/reading/letter_grid_match/grid_match_model.dart';
import 'package:larnes_mobile/trainers/reading/letter_grid_match/grid_match_scene.dart';
import 'package:larnes_mobile/trainers/reading/letter_model.dart';
import 'package:larnes_mobile/trainers/shared/param_coerce.dart';
import 'package:larnes_mobile/trainers/shared/seeded_rng.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';

/// Web v2: `platform/src/trainers/reading/letter-grid-match/component.tsx`
class LetterGridMatchTrainer extends StatefulWidget {
  const LetterGridMatchTrainer({
    super.key,
    required this.params,
    this.onComplete,
  });

  final Map<String, dynamic> params;
  final VoidCallback? onComplete;

  @override
  State<LetterGridMatchTrainer> createState() => _LetterGridMatchTrainerState();
}

class _LetterGridMatchTrainerState extends State<LetterGridMatchTrainer> {
  late final int _layoutSalt;
  late final List<String> _practiceLetters;
  late final int _seed;
  late final GridRound _round;
  late final Map<String, String> _tileColors;

  int get _filledCount =>
      coerceInt(widget.params['filledCount']) ??
      coerceInt(widget.params['entityCount']) ??
      4;

  int get _gridSize =>
      coerceInt(widget.params['gridSize']) ?? coerceInt(widget.params['digit']) ?? 3;

  String get _letterCase => widget.params['letterCase'] as String? ?? 'upper';

  String get _practiceLettersRaw =>
      widget.params['practiceLetters'] as String? ?? 'А';

  @override
  void initState() {
    super.initState();
    _layoutSalt = createLayoutSalt();
    _practiceLetters = parsePracticeLetters(_practiceLettersRaw);
    _seed = buildRoundSeed([
      _filledCount,
      _gridSize,
      _practiceLettersRaw,
      _letterCase,
      _layoutSalt,
    ]);
    _round = buildGridRound(
      filledCount: _filledCount,
      gridSize: _gridSize,
      letterCase: _letterCase,
      practiceLetters: _practiceLetters,
      seed: _seed,
    );
    final rng = createSeededRng(_seed + 23);
    _tileColors = {
      for (final tile in _round.poolTiles)
        tile.id: pickLetterDisplayColor(rng),
    };
  }

  @override
  Widget build(BuildContext context) {
    return TrainerScene(
      child: GridMatchScene(
        onComplete: () => widget.onComplete?.call(),
        round: _round,
        tileColors: _tileColors,
      ),
    );
  }
}
