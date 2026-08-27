import 'dart:async';

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/math/fruit_count_tap/fruit_answer_bar_layout.dart';
import 'package:larnes_mobile/trainers/math/fruit_count_tap/fruit_reveal.dart';
import 'package:larnes_mobile/trainers/reading/letter_colors.dart';
import 'package:larnes_mobile/trainers/reading/letter_find_tap/letter_field_scene.dart';
import 'package:larnes_mobile/trainers/reading/letter_model.dart';
import 'package:larnes_mobile/trainers/reading/letter_first_by_sound/letter_choice_bar.dart';
import 'package:larnes_mobile/trainers/reading/letter_first_by_sound/letter_first_by_sound_audio.dart';
import 'package:larnes_mobile/trainers/reading/letter_first_by_sound/letter_first_by_sound_model.dart';
import 'package:larnes_mobile/trainers/reading/letter_first_by_sound/word_card.dart';
import 'package:larnes_mobile/trainers/reading/sound_play_button.dart';
import 'package:larnes_mobile/trainers/runtime/runtime_snapshot.dart';
import 'package:larnes_mobile/trainers/shared/first_words/play_first_word_audio.dart';
import 'package:larnes_mobile/trainers/shared/first_words/resolve_first_word.dart';
import 'package:larnes_mobile/trainers/shared/instruction/load_trainer_instruction_duration.dart';
import 'package:larnes_mobile/trainers/shared/instruction/trainer_instruction_scene.dart';
import 'package:larnes_mobile/trainers/shared/instruction/trainer_instruction_typewriter.dart';
import 'package:larnes_mobile/trainers/shared/seeded_rng.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';
import 'package:larnes_mobile/trainers/shared/trainer_timings.dart';

enum LetterFirstBySoundPhase { instruction, countdown, play }

/// Web v2: `platform/src/trainers/reading/letter-first-by-sound/component.tsx`
class LetterFirstBySoundTrainer extends StatefulWidget {
  const LetterFirstBySoundTrainer({
    super.key,
    required this.params,
    this.onComplete,
  });

  final Map<String, dynamic> params;
  final VoidCallback? onComplete;

  @override
  State<LetterFirstBySoundTrainer> createState() =>
      _LetterFirstBySoundTrainerState();
}

class _LetterFirstBySoundTrainerState extends State<LetterFirstBySoundTrainer> {
  static const _instructionText =
      'Прослушай слово и нажми на первую букву этого слова';
  static const _countdownLabels = ['3', '2', '1', 'СТАРТ'];
  static const _countdownStepMs = 750;
  static const _countdownColor = Color(0xFFDC2626);
  static const _playFailMessage = 'Не удалось проиграть слово';

  late final int? _snapshotSeed;
  late final int _layoutSalt;
  late List<FirstBySoundRound> _rounds;
  late List<String> _choices;
  late Map<String, Color> _choiceColors;
  var _roundIndex = 0;

  LetterFirstBySoundPhase _phase = LetterFirstBySoundPhase.instruction;
  String _countdownLabel = _countdownLabels.first;
  var _instructionLength = 0;
  String? _selectedLetter;
  String? _wrongLetter;
  var _isCompleted = false;
  var _isStimulusRevealComplete = false;
  var _isAnswerRevealComplete = false;
  var _completeCalled = false;
  var _playedWord = false;
  Object _runToken = Object();

  final _instructionTypewriter = TrainerInstructionTypewriter();
  Timer? _countdownTimer;
  Timer? _stimulusRevealTimer;
  Timer? _answerRevealTimer;
  Timer? _completeTimer;

  FirstBySoundRound? get _current =>
      _rounds.isEmpty ? null : _rounds[_roundIndex.clamp(0, _rounds.length - 1)];

  @override
  void initState() {
    super.initState();
    _snapshotSeed = readTrainerSnapshotSeed(
      'letter-first-by-sound',
      widget.params,
    );
    _layoutSalt = _snapshotSeed == null ? createLayoutSalt() : 0;
    _startSession();
  }

  @override
  void didUpdateWidget(LetterFirstBySoundTrainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_semanticParamsChanged(oldWidget.params, widget.params)) {
      _startSession();
    }
  }

  @override
  void dispose() {
    _instructionTypewriter.cancel();
    _countdownTimer?.cancel();
    _stimulusRevealTimer?.cancel();
    _answerRevealTimer?.cancel();
    _completeTimer?.cancel();
    unawaited(cancelLetterFirstBySoundAudio());
    super.dispose();
  }

  bool _semanticParamsChanged(
    Map<String, dynamic> previous,
    Map<String, dynamic> next,
  ) {
    return previous['practiceLetters'] != next['practiceLetters'] ||
        previous['rounds'] != next['rounds'] ||
        previous['letterCase'] != next['letterCase'] ||
        previous['distractorCount'] != next['distractorCount'];
  }

  void _startSession() {
    final runToken = Object();
    _runToken = runToken;
    _instructionTypewriter.cancel();
    _countdownTimer?.cancel();
    _stimulusRevealTimer?.cancel();
    _answerRevealTimer?.cancel();
    _completeTimer?.cancel();
    unawaited(cancelLetterFirstBySoundAudio());

    final practiceLetters = resolveFirstBySoundPracticeLetters(
      widget.params['practiceLetters']?.toString(),
    );
    final rounds = widget.params['rounds'] as int? ?? defaultFirstBySoundRounds;
    final planRng = _snapshotSeed == null
        ? createSeededRng(
            buildFirstBySoundPlanSeed(
              practiceLetters: formatPracticeLetters(practiceLetters),
              rounds: rounds,
              layoutSalt: _layoutSalt,
            ),
          )
        : TrainerSnapshotRandom(_snapshotSeed!).nextDouble;
    _rounds = buildRoundPlan(
      letters: practiceLetters,
      rng: planRng,
      rounds: rounds,
    );
    _roundIndex = 0;
    _applyRoundChoices();

    setState(() {
      _phase = LetterFirstBySoundPhase.instruction;
      _instructionLength = 0;
      _countdownLabel = _countdownLabels.first;
      _selectedLetter = null;
      _wrongLetter = null;
      _isCompleted = false;
      _isStimulusRevealComplete = false;
      _isAnswerRevealComplete = false;
      _completeCalled = false;
      _playedWord = false;
    });

    unawaited(_runInstruction(runToken));
  }

  void _applyRoundChoices() {
    final current = _current;
    if (current == null) {
      _choices = const [];
      _choiceColors = const {};
      return;
    }

    final letterCase = widget.params['letterCase'] as String? ?? 'upper';
    final distractorCount = widget.params['distractorCount'] as int? ?? 3;
    final rng = _snapshotSeed == null
        ? createSeededRng(
            buildFirstBySoundChoicesSeed(
              slug: current.slug,
              letterCase: letterCase,
              distractorCount: distractorCount,
              layoutSalt: _layoutSalt,
              roundIndex: _roundIndex,
            ),
          )
        : TrainerSnapshotRandom(
            hashParamsSeed([
              _snapshotSeed!,
              current.slug,
              _roundIndex,
              'first-by-sound-choices',
            ]),
          ).nextDouble;
    _choices = buildLetterChoices(
      BuildLetterChoicesInput(
        distractorCount: distractorCount,
        firstLetter: current.firstLetter,
        letterCase: letterCase,
        rng: rng,
      ),
    );
    _choiceColors = {
      for (final letter in _choices)
        letter: letterDisplayColorFromHex(pickLetterDisplayColor(rng)),
    };
  }

  Future<void> _runInstruction(Object runToken) async {
    final durationMs = await loadTrainerInstructionDurationMs(
      assetPath: getLetterFirstBySoundInstructionAudioAsset(),
      playbackRate: kLetterFirstBySoundInstructionPlaybackRate,
      fallbackMs: kLetterFirstBySoundInstructionDurationFallbackMs,
    );
    if (!mounted || !identical(runToken, _runToken)) {
      return;
    }

    _instructionTypewriter.start(
      text: _instructionText,
      durationMs: durationMs,
      isCurrent: () => mounted && identical(runToken, _runToken),
      onLength: (length) {
        if (!mounted || !identical(runToken, _runToken)) {
          return;
        }
        setState(() => _instructionLength = length);
      },
    );

    await playLetterFirstBySoundInstruction();
    if (!mounted || !identical(runToken, _runToken)) {
      return;
    }

    _instructionTypewriter.cancel();
    setState(() {
      _instructionLength = _instructionText.length;
      _phase = LetterFirstBySoundPhase.countdown;
    });
    _runCountdown(runToken);
  }

  void _runCountdown(Object runToken) {
    _countdownTimer?.cancel();
    var index = 0;

    void showNext() {
      if (!mounted || !identical(runToken, _runToken)) {
        return;
      }

      if (index >= _countdownLabels.length) {
        setState(() => _phase = LetterFirstBySoundPhase.play);
        _scheduleStimulusReveal();
        unawaited(_playCurrentWord());
        return;
      }

      setState(() => _countdownLabel = _countdownLabels[index]);
      index += 1;
      _countdownTimer = Timer(
        const Duration(milliseconds: _countdownStepMs),
        showNext,
      );
    }

    showNext();
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

  Future<void> _playCurrentWord() async {
    final current = _current;
    if (current == null || _playedWord) {
      return;
    }

    _playedWord = true;
    final played = await playFirstWordAudio(current.slug);
    if (played || !mounted || _isCompleted) {
      return;
    }

    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      const SnackBar(
        content: Text(_playFailMessage),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handlePlayWord() {
    if (_isCompleted || _phase != LetterFirstBySoundPhase.play) {
      return;
    }

    _playedWord = false;
    unawaited(_playCurrentWord());
  }

  void _handleSelectLetter(String letter) {
    final current = _current;
    final letterCase = widget.params['letterCase'] as String? ?? 'upper';

    if (_phase != LetterFirstBySoundPhase.play ||
        _isCompleted ||
        !_isAnswerRevealComplete ||
        _selectedLetter != null ||
        current == null) {
      return;
    }

    if (!isCorrectLetterChoice(current.firstLetter, letterCase, letter)) {
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

  void _advanceRound() {
    setState(() {
      _roundIndex += 1;
      _applyRoundChoices();
      _selectedLetter = null;
      _wrongLetter = null;
      _isCompleted = false;
      _isStimulusRevealComplete = false;
      _isAnswerRevealComplete = false;
      _playedWord = false;
    });
    _scheduleStimulusReveal();
    unawaited(_playCurrentWord());
  }

  void _scheduleComplete() {
    _completeTimer?.cancel();
    _completeTimer = Timer(
      const Duration(milliseconds: TrainerTimings.completeDelayMs),
      () {
        if (!mounted) {
          return;
        }

        if (_roundIndex + 1 < _rounds.length) {
          _advanceRound();
          return;
        }

        if (_completeCalled) {
          return;
        }

        _completeCalled = true;
        widget.onComplete?.call();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_phase == LetterFirstBySoundPhase.instruction) {
      return TrainerInstructionScene(
        length: _instructionLength,
        text: _instructionText,
      );
    }

    if (_phase == LetterFirstBySoundPhase.countdown) {
      return TrainerScene(
        child: Center(
          child: Text(
            _countdownLabel,
            style: const TextStyle(
              fontSize: 96,
              fontWeight: FontWeight.w700,
              height: 1,
              color: _countdownColor,
            ),
          ),
        ),
      );
    }

    final current = _current;
    final padding = MediaQuery.paddingOf(context);
    final left = padding.left > 14 ? 0.0 : 14.0;
    final bottom = padding.bottom > 14 ? 0.0 : 14.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final answerLayout = computeFruitAnswerBarLayout(
          viewportWidth: constraints.maxWidth,
          viewportHeight: constraints.maxHeight,
        );

        return TrainerScene(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      WordCard(
                        key: ValueKey(current?.slug ?? 'empty'),
                        imageSrc: current == null
                            ? null
                            : getFirstWordImageWidgetAsset(current.slug),
                        disabled: _isCompleted,
                        onPlay: _handlePlayWord,
                      ),
                      if (_isStimulusRevealComplete) ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          width: constraints.maxWidth - 32,
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
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Positioned(
                left: left,
                bottom: bottom,
                child: SoundPlayButton(
                  disabled: _isCompleted,
                  onPressed: _handlePlayWord,
                  variant: SoundPlayButtonVariant.chrome,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
