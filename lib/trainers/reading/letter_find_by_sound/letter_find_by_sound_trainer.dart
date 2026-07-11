import 'dart:async';

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/math/fruit_count_tap/fruit_reveal.dart';
import 'package:larnes_mobile/trainers/reading/letter_colors.dart';
import 'package:larnes_mobile/trainers/reading/letter_find_by_sound/find_by_sound_model.dart';
import 'package:larnes_mobile/trainers/reading/letter_find_tap/letter_field_scene.dart';
import 'package:larnes_mobile/trainers/reading/letter_find_tap/letter_find_tap_layout.dart';
import 'package:larnes_mobile/trainers/reading/letter_model.dart';
import 'package:larnes_mobile/trainers/reading/sound_play_button.dart';
import 'package:larnes_mobile/trainers/shared/seeded_rng.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';
import 'package:larnes_mobile/trainers/shared/trainer_timings.dart';

/// Web v2: `platform/src/trainers/reading/letter-find-by-sound/component.tsx`
class LetterFindBySoundTrainer extends StatefulWidget {
  const LetterFindBySoundTrainer({
    super.key,
    required this.params,
    this.onComplete,
  });

  final Map<String, dynamic> params;
  final VoidCallback? onComplete;

  @override
  State<LetterFindBySoundTrainer> createState() => _LetterFindBySoundTrainerState();
}

class _LetterFindBySoundTrainerState extends State<LetterFindBySoundTrainer> {
  late final int _layoutSalt;
  late final List<PlacedLetter> _letters;
  late final String _displayLetter;

  final Set<String> _foundIds = {};
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
    final targetLetter =
        normalizeTargetLetter(widget.params['letter'] as String? ?? 'А');
    final letterCase = widget.params['letterCase'] as String? ?? 'upper';
    _displayLetter = applyLetterCase(targetLetter, letterCase);
    _letters = _buildLetters(targetLetter, letterCase);
    _scheduleReveal();
  }

  List<PlacedLetter> _buildLetters(String targetLetter, String letterCase) {
    final distractorCount = widget.params['distractorCount'] as int? ?? 0;
    final seed = buildSoundFindRoundSeed(
      targetLetter: targetLetter,
      letterCase: letterCase,
      distractorCount: distractorCount,
      layoutSalt: _layoutSalt,
    );
    final rng = createSeededRng(seed);
    final tokens = buildSoundFindTokens(
      BuildSoundFindFieldInput(
        distractorCount: distractorCount,
        letterCase: letterCase,
        rng: rng,
        targetLetter: targetLetter,
      ),
    );

    return placeLetterTokens(assignLetterDisplayColors(tokens, rng), rng);
  }

  void _scheduleReveal() {
    _revealTimer?.cancel();

    if (_letters.isEmpty) {
      setState(() => _isRevealComplete = true);
      return;
    }

    setState(() => _isRevealComplete = false);

    _revealTimer = Timer(
      Duration(milliseconds: getFruitRevealTotalMs(_letters.length)),
      () {
        if (!mounted) {
          return;
        }
        setState(() => _isRevealComplete = true);
      },
    );
  }

  void _handlePlaySound() {
    if (_isCompleted) {
      return;
    }

    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(getSoundStubMessage(_displayLetter)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleTap(String id) {
    if (_isCompleted || !_isRevealComplete || _foundIds.contains(id)) {
      return;
    }

    final tokenIndex = _letters.indexWhere((letter) => letter.id == id);
    if (tokenIndex < 0) {
      return;
    }
    final token = _letters[tokenIndex];

    if (!token.isTarget) {
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
      _foundIds.add(id);
      _isCompleted = true;
    });
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
    _revealTimer?.cancel();
    _completeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TrainerSceneColumn(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: Center(
              child: SoundPlayButton(
                disabled: _isCompleted,
                onPressed: _handlePlaySound,
              ),
            ),
          ),
          Expanded(
            child: LetterFieldScene(
              letters: _letters,
              disabled: _isCompleted || !_isRevealComplete,
              foundIds: _foundIds,
              onTap: _handleTap,
              wrongId: _wrongId,
            ),
          ),
        ],
      ),
    );
  }
}
