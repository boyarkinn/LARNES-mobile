import 'dart:async';

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/math/fruit_count_tap/fruit_reveal.dart';
import 'package:larnes_mobile/trainers/reading/letter_colors.dart';
import 'package:larnes_mobile/trainers/reading/letter_find_tap/letter_field_scene.dart';
import 'package:larnes_mobile/trainers/reading/letter_model.dart';
import 'package:larnes_mobile/trainers/reading/letter_orientation_pick/orientation_board.dart';
import 'package:larnes_mobile/trainers/reading/letter_orientation_pick/orientation_pick_model.dart';
import 'package:larnes_mobile/trainers/shared/seeded_rng.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';
import 'package:larnes_mobile/trainers/shared/trainer_timings.dart';

/// Web v2: `platform/src/trainers/reading/letter-orientation-pick/component.tsx`
class LetterOrientationPickTrainer extends StatefulWidget {
  const LetterOrientationPickTrainer({
    super.key,
    required this.params,
    this.onComplete,
  });

  final Map<String, dynamic> params;
  final VoidCallback? onComplete;

  @override
  State<LetterOrientationPickTrainer> createState() =>
      _LetterOrientationPickTrainerState();
}

class _LetterOrientationPickTrainerState extends State<LetterOrientationPickTrainer> {
  late final int _layoutSalt;
  late final List<OrientationOption> _options;
  late final Color _displayColor;

  String? _selectedId;
  String? _wrongId;
  var _isCompleted = false;
  var _isRevealComplete = false;
  var _completeCalled = false;
  Timer? _revealTimer;
  Timer? _completeTimer;

  @override
  void initState() {
    super.initState();
    _layoutSalt = createLayoutSalt();
    final round = _buildRound();
    _options = round.options;
    _displayColor = round.displayColor;
    _scheduleReveal();
  }

  ({List<OrientationOption> options, Color displayColor}) _buildRound() {
    final mainLetter =
        normalizeTargetLetter(widget.params['letter'] as String? ?? 'А');
    final letterCase = widget.params['letterCase'] as String? ?? 'upper';
    final entityCount = widget.params['entityCount'] as int? ?? 4;

    final seed = buildOrientationPickRoundSeed([
      mainLetter,
      entityCount,
      letterCase,
      _layoutSalt,
    ]);
    final rng = createSeededRng(seed);
    final options = buildOrientationOptions(
      BuildOrientationOptionsInput(
        letter: mainLetter,
        letterCase: letterCase,
        optionCount: entityCount,
        rng: rng,
      ),
    );
    final displayColorHex = pickLetterDisplayColor(rng);

    return (
      options: options,
      displayColor: letterDisplayColorFromHex(displayColorHex),
    );
  }

  void _scheduleReveal() {
    _revealTimer?.cancel();

    if (_options.isEmpty) {
      setState(() => _isRevealComplete = true);
      return;
    }

    setState(() => _isRevealComplete = false);

    _revealTimer = Timer(
      Duration(milliseconds: getFruitRevealTotalMs(_options.length)),
      () {
        if (!mounted) {
          return;
        }
        setState(() => _isRevealComplete = true);
      },
    );
  }

  void _handleSelect(String id) {
    if (_isCompleted || !_isRevealComplete || _selectedId == id) {
      return;
    }

    final optionIndex = _options.indexWhere((item) => item.id == id);
    if (optionIndex < 0) {
      return;
    }
    final option = _options[optionIndex];

    if (!option.isUpright) {
      setState(() => _wrongId = id);
      Future<void>.delayed(
        const Duration(milliseconds: TrainerTimings.wrongFeedbackMs),
        () {
          if (!mounted) {
            return;
          }
          setState(() {
            if (_wrongId == id) {
              _wrongId = null;
            }
          });
        },
      );
      return;
    }

    setState(() {
      _selectedId = id;
      _isCompleted = true;
    });
    _scheduleComplete();
  }

  void _scheduleComplete() {
    if (_completeCalled || widget.onComplete == null) {
      return;
    }

    if (!isUprightOptionSelected(_selectedId, _options)) {
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
    _revealTimer?.cancel();
    _completeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TrainerScene(
      child: OrientationBoard(
        options: _options,
        displayColor: _displayColor,
        disabled: _isCompleted,
        isRevealComplete: _isRevealComplete,
        selectedId: _selectedId,
        wrongId: _wrongId,
        onSelect: _handleSelect,
      ),
    );
  }
}
