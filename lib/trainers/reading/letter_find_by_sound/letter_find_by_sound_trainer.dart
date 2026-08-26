import 'dart:async';

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/math/fruit_count_tap/fruit_reveal.dart';
import 'package:larnes_mobile/trainers/reading/letter_colors.dart';
import 'package:larnes_mobile/trainers/reading/letter_find_by_sound/find_by_sound_model.dart';
import 'package:larnes_mobile/trainers/reading/letter_find_by_sound/letter_find_by_sound_audio.dart';
import 'package:larnes_mobile/trainers/reading/letter_find_tap/letter_field_scene.dart';
import 'package:larnes_mobile/trainers/reading/letter_find_tap/letter_find_tap_layout.dart';
import 'package:larnes_mobile/trainers/reading/letter_model.dart';
import 'package:larnes_mobile/trainers/reading/sound_play_button.dart';
import 'package:larnes_mobile/trainers/shared/instruction/load_trainer_instruction_duration.dart';
import 'package:larnes_mobile/trainers/shared/instruction/trainer_instruction_scene.dart';
import 'package:larnes_mobile/trainers/shared/instruction/trainer_instruction_typewriter.dart';
import 'package:larnes_mobile/trainers/shared/letters_syllables/play_letter_syllable_audio.dart';
import 'package:larnes_mobile/trainers/shared/seeded_rng.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';
import 'package:larnes_mobile/trainers/shared/trainer_timings.dart';

enum LetterFindBySoundPhase { instruction, countdown, play }

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
  State<LetterFindBySoundTrainer> createState() =>
      _LetterFindBySoundTrainerState();
}

class _LetterFindBySoundTrainerState extends State<LetterFindBySoundTrainer> {
  static const _instructionText = 'Найди букву';
  static const _countdownLabels = ['3', '2', '1', 'СТАРТ'];
  static const _countdownStepMs = 750;
  static const _countdownColor = Color(0xFFDC2626);

  late final int _layoutSalt;
  late List<PlacedLetter> _letters;
  late List<String> _practiceLetters;
  late String _targetLetter;
  late String _displayLetter;
  var _roundIndex = 0;

  LetterFindBySoundPhase _phase = LetterFindBySoundPhase.instruction;
  String _countdownLabel = _countdownLabels.first;
  var _instructionLength = 0;
  final Set<String> _foundIds = {};
  String? _wrongId;
  var _isCompleted = false;
  var _isRevealComplete = false;
  var _completeCalled = false;
  Object _runToken = Object();

  final _instructionTypewriter = TrainerInstructionTypewriter();
  Timer? _countdownTimer;
  Timer? _revealTimer;
  Timer? _completeTimer;

  @override
  void initState() {
    super.initState();
    _layoutSalt = createLayoutSalt();
    _startSession();
  }

  @override
  void didUpdateWidget(LetterFindBySoundTrainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_semanticParamsChanged(oldWidget.params, widget.params)) {
      _startSession();
    }
  }

  @override
  void dispose() {
    _instructionTypewriter.cancel();
    _countdownTimer?.cancel();
    _revealTimer?.cancel();
    _completeTimer?.cancel();
    unawaited(cancelLetterFindBySoundAudio());
    super.dispose();
  }

  bool _semanticParamsChanged(
    Map<String, dynamic> previous,
    Map<String, dynamic> next,
  ) {
    return previous['practiceLetters'] != next['practiceLetters'] ||
        previous['letter'] != next['letter'] ||
        previous['letterCase'] != next['letterCase'] ||
        previous['distractorCount'] != next['distractorCount'];
  }

  void _startSession() {
    final runToken = Object();
    _runToken = runToken;
    _instructionTypewriter.cancel();
    _countdownTimer?.cancel();
    _revealTimer?.cancel();
    _completeTimer?.cancel();
    unawaited(cancelLetterFindBySoundAudio());

    _practiceLetters = resolveSoundPracticeLetters(
      widget.params['practiceLetters']?.toString(),
      widget.params['letter']?.toString(),
    );
    if (_practiceLetters.isEmpty) {
      _practiceLetters = ['А'];
    }
    _roundIndex = 0;
    _applyRoundLetters();

    setState(() {
      _phase = LetterFindBySoundPhase.instruction;
      _instructionLength = 0;
      _countdownLabel = _countdownLabels.first;
      _foundIds.clear();
      _wrongId = null;
      _isCompleted = false;
      _isRevealComplete = false;
      _completeCalled = false;
    });

    unawaited(_runInstruction(runToken));
  }

  void _applyRoundLetters() {
    final letterCase = widget.params['letterCase'] as String? ?? 'upper';
    _targetLetter = _practiceLetters[_roundIndex];
    _displayLetter = applyLetterCase(_targetLetter, letterCase);
    _letters = _buildLetters(_targetLetter, letterCase);
  }

  List<PlacedLetter> _buildLetters(String targetLetter, String letterCase) {
    final distractorCount = widget.params['distractorCount'] as int? ?? 0;
    final seed = buildSoundFindRoundSeed(
      targetLetter: targetLetter,
      letterCase: letterCase,
      distractorCount: distractorCount,
      layoutSalt: _layoutSalt,
      roundIndex: _roundIndex,
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

  Future<void> _runInstruction(Object runToken) async {
    final durationMs = await loadTrainerInstructionDurationMs(
      assetPath: getLetterFindBySoundInstructionAudioAsset(),
      playbackRate: kLetterFindBySoundInstructionPlaybackRate,
      fallbackMs: kLetterFindBySoundInstructionDurationFallbackMs,
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

    await playLetterFindBySoundInstruction();
    if (!mounted || !identical(runToken, _runToken)) {
      return;
    }

    _instructionTypewriter.cancel();
    setState(() {
      _instructionLength = _instructionText.length;
      _phase = LetterFindBySoundPhase.countdown;
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
        setState(() => _phase = LetterFindBySoundPhase.play);
        _scheduleReveal();
        unawaited(_playTargetLetter());
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

  Future<void> _playTargetLetter() async {
    final played = await playLetterSyllableAudio(_targetLetter);
    if (played || !mounted || _isCompleted) {
      return;
    }

    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(getSoundStubMessage(_displayLetter)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handlePlaySound() {
    if (_isCompleted || _phase != LetterFindBySoundPhase.play) {
      return;
    }

    unawaited(_playTargetLetter());
  }

  void _handleTap(String id) {
    if (_phase != LetterFindBySoundPhase.play ||
        _isCompleted ||
        !_isRevealComplete ||
        _foundIds.contains(id)) {
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

  void _advanceRound() {
    setState(() {
      _roundIndex += 1;
      _applyRoundLetters();
      _foundIds.clear();
      _wrongId = null;
      _isCompleted = false;
      _isRevealComplete = false;
    });
    _scheduleReveal();
    unawaited(_playTargetLetter());
  }

  void _scheduleComplete() {
    _completeTimer?.cancel();
    _completeTimer = Timer(
      const Duration(milliseconds: TrainerTimings.completeAfterBurstMs),
      () {
        if (!mounted) {
          return;
        }

        if (_roundIndex + 1 < _practiceLetters.length) {
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
    if (_phase == LetterFindBySoundPhase.instruction) {
      return TrainerInstructionScene(
        length: _instructionLength,
        text: _instructionText,
      );
    }

    if (_phase == LetterFindBySoundPhase.countdown) {
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

    final padding = MediaQuery.paddingOf(context);
    final left = padding.left > 14 ? 0.0 : 14.0;
    final bottom = padding.bottom > 14 ? 0.0 : 14.0;

    return TrainerSceneFill(
      child: Stack(
        fit: StackFit.expand,
        children: [
          LetterFieldScene(
            letters: _letters,
            disabled: _isCompleted || !_isRevealComplete,
            foundIds: _foundIds,
            onTap: _handleTap,
            wrongId: _wrongId,
          ),
          Positioned(
            left: left,
            bottom: bottom,
            child: SoundPlayButton(
              disabled: _isCompleted,
              onPressed: _handlePlaySound,
              variant: SoundPlayButtonVariant.chrome,
            ),
          ),
        ],
      ),
    );
  }
}
