import 'dart:async';

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/math/fruit_count_tap/fruit_answer_bar_layout.dart';
import 'package:larnes_mobile/trainers/math/fruit_count_tap/fruit_reveal.dart';
import 'package:larnes_mobile/trainers/reading/letter_colors.dart';
import 'package:larnes_mobile/trainers/reading/letter_find_tap/letter_field_scene.dart';
import 'package:larnes_mobile/trainers/reading/letter_first_by_image/first_by_image_model.dart';
import 'package:larnes_mobile/trainers/reading/letter_first_by_image/letter_choice_bar.dart';
import 'package:larnes_mobile/trainers/reading/letter_first_by_image/word_card.dart';
import 'package:larnes_mobile/trainers/reading/letter_model.dart';
import 'package:larnes_mobile/trainers/reading/reading_word_catalogs.dart';
import 'package:larnes_mobile/trainers/reading/sound_play_button.dart';
import 'package:larnes_mobile/trainers/shared/seeded_rng.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';
import 'package:larnes_mobile/trainers/shared/trainer_timings.dart';

/// Web v2: `platform/src/trainers/reading/letter-first-by-image/component.tsx`
class LetterFirstByImageTrainer extends StatefulWidget {
  const LetterFirstByImageTrainer({
    super.key,
    required this.params,
    this.onComplete,
  });

  final Map<String, dynamic> params;
  final VoidCallback? onComplete;

  @override
  State<LetterFirstByImageTrainer> createState() =>
      _LetterFirstByImageTrainerState();
}

class _LetterFirstByImageTrainerState extends State<LetterFirstByImageTrainer> {
  late final String _wordSlug;
  late final String _displayWord;
  late final String? _imageSrc;
  late final String _firstLetter;
  late final String _letterCase;
  late final List<String> _choices;
  late final Map<String, Color> _choiceColors;

  String? _selectedLetter;
  String? _wrongLetter;
  var _isCompleted = false;
  var _isStimulusRevealComplete = false;
  var _isAnswerRevealComplete = false;
  var _completeCalled = false;
  Timer? _stimulusRevealTimer;
  Timer? _answerRevealTimer;
  Timer? _completeTimer;

  @override
  void initState() {
    super.initState();
    _wordSlug = widget.params['wordSlug'] as String? ?? 'stork';
    final wordCase = widget.params['wordCase'] as String? ?? 'upper';
    _letterCase = widget.params['letterCase'] as String? ?? 'upper';
    final distractorCount = widget.params['distractorCount'] as int? ?? 3;

    _displayWord = applyWordCase(getFirstByImageWordLabel(_wordSlug), wordCase);
    _imageSrc = getFirstByImageWordImageSrc(_wordSlug);
    _firstLetter = getFirstLetterFromWordSlug(_wordSlug);

    final layoutSalt = createLayoutSalt();
    final seed = buildFirstByImageChoicesSeed(
      wordSlug: _wordSlug,
      wordCase: wordCase,
      letterCase: _letterCase,
      distractorCount: distractorCount,
      layoutSalt: layoutSalt,
    );
    final rng = createSeededRng(seed);
    _choices = buildLetterChoices(
      BuildLetterChoicesInput(
        distractorCount: distractorCount,
        firstLetter: _firstLetter,
        letterCase: _letterCase,
        rng: rng,
        wordSlug: _wordSlug,
      ),
    );
    _choiceColors = {
      for (final letter in _choices)
        letter: letterDisplayColorFromHex(pickLetterDisplayColor(rng)),
    };

    _scheduleStimulusReveal();
  }

  void _scheduleStimulusReveal() {
    _stimulusRevealTimer?.cancel();
    _answerRevealTimer?.cancel();

    setState(() {
      _isStimulusRevealComplete = false;
      _isAnswerRevealComplete = false;
    });

    _stimulusRevealTimer = Timer(
      Duration(milliseconds: getFruitRevealTotalMs(1)),
      () {
        if (!mounted) {
          return;
        }
        setState(() => _isStimulusRevealComplete = true);
        _scheduleAnswerReveal();
      },
    );
  }

  void _scheduleAnswerReveal() {
    _answerRevealTimer?.cancel();

    if (_choices.isEmpty) {
      setState(() => _isAnswerRevealComplete = true);
      return;
    }

    setState(() => _isAnswerRevealComplete = false);

    _answerRevealTimer = Timer(
      Duration(milliseconds: getAnswerRevealTotalMs(_choices.length)),
      () {
        if (!mounted) {
          return;
        }
        setState(() => _isAnswerRevealComplete = true);
      },
    );
  }

  void _handlePlayWord() {
    if (_isCompleted) {
      return;
    }

    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(
      SnackBar(
        content: Text(getWordAudioStubMessage(_displayWord)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleSelectLetter(String letter) {
    if (_isCompleted ||
        !_isAnswerRevealComplete ||
        _selectedLetter != null) {
      return;
    }

    if (!isCorrectLetterChoice(_firstLetter, _letterCase, letter)) {
      setState(() => _wrongLetter = letter);
      Future<void>.delayed(
        const Duration(milliseconds: TrainerTimings.wrongFeedbackMs),
        () {
          if (!mounted) {
            return;
          }
          setState(() {
            if (_wrongLetter == letter) {
              _wrongLetter = null;
            }
          });
        },
      );
      return;
    }

    setState(() {
      _selectedLetter = letter;
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
    _stimulusRevealTimer?.cancel();
    _answerRevealTimer?.cancel();
    _completeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final answerLayout = computeFruitAnswerBarLayout(
          viewportWidth: constraints.maxWidth,
          viewportHeight: constraints.maxHeight,
        );

        return TrainerSceneColumn(
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: WordCard(
                      displayWord: _displayWord,
                      imageSrc: _imageSrc,
                      disabled: _isCompleted,
                      onPlay: _handlePlayWord,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SoundPlayButton(
                  disabled: _isCompleted,
                  onPressed: _handlePlayWord,
                ),
              ],
            ),
          ),
          footer: _isStimulusRevealComplete
              ? Padding(
                  padding: EdgeInsets.fromLTRB(
                    answerLayout.horizontalPadding,
                    answerLayout.paddingTop,
                    answerLayout.horizontalPadding,
                    answerLayout.paddingBottom,
                  ),
                  child: LetterChoiceBar(
                    choices: _choices,
                    choiceColors: _choiceColors,
                    disabled: _isCompleted,
                    isRevealComplete: _isAnswerRevealComplete,
                    onSelect: _handleSelectLetter,
                    selectedLetter: _selectedLetter,
                    wrongLetter: _wrongLetter,
                    buttonHeight: answerLayout.buttonHeight,
                    fontSize: answerLayout.fontSize,
                    viewportWidth: constraints.maxWidth,
                  ),
                )
              : null,
        );
      },
    );
  }
}
