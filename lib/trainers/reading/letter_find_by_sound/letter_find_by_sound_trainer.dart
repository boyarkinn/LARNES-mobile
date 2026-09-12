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
import 'package:larnes_mobile/trainers/runtime/runtime_snapshot.dart';
import 'package:larnes_mobile/trainers/shared/instruction/load_trainer_instruction_duration.dart';
import 'package:larnes_mobile/trainers/shared/instruction/trainer_instruction_scene.dart';
import 'package:larnes_mobile/trainers/shared/instruction/trainer_instruction_typewriter.dart';
import 'package:larnes_mobile/trainers/shared/letters_syllables/play_letter_syllable_audio.dart';
import 'package:larnes_mobile/trainers/shared/seeded_rng.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';
import 'package:larnes_mobile/trainers/shared/trainer_timings.dart';

enum LetterFindBySoundPhase { instruction, countdown, listen, play }

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
  static const _countdownColor = Color(0xFF249B73);

  late final int? _snapshotSeed;
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
  var _isSoundPlaying = false;
  var _completeCalled = false;
  Object _runToken = Object();

  final _instructionTypewriter = TrainerInstructionTypewriter();
  Timer? _countdownTimer;
  Timer? _revealTimer;
  Timer? _completeTimer;

  @override
  void initState() {
    super.initState();
    _snapshotSeed = readTrainerSnapshotSeed(
      'letter-find-by-sound',
      widget.params,
    );
    _layoutSalt = _snapshotSeed == null ? createLayoutSalt() : 0;
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
      _isSoundPlaying = false;
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
    final rng = _snapshotSeed == null
        ? createSeededRng(
            buildSoundFindRoundSeed(
              targetLetter: targetLetter,
              letterCase: letterCase,
              distractorCount: distractorCount,
              layoutSalt: _layoutSalt,
              roundIndex: _roundIndex,
            ),
          )
        : TrainerSnapshotRandom(
            hashParamsSeed([_snapshotSeed, targetLetter, _roundIndex, 'sound']),
          ).nextDouble;
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
        setState(() => _phase = LetterFindBySoundPhase.listen);
        unawaited(_playTargetLetter(revealAfter: true));
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

  Future<void> _playTargetLetter({bool revealAfter = false}) async {
    setState(() => _isSoundPlaying = true);
    final played = await playLetterSyllableAudio(_targetLetter);
    if (!mounted || _isCompleted) {
      return;
    }
    setState(() => _isSoundPlaying = false);

    if (played) {
      if (revealAfter) {
        setState(() => _phase = LetterFindBySoundPhase.play);
        _scheduleReveal();
      }
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
    if (_isCompleted ||
        _isSoundPlaying ||
        (_phase != LetterFindBySoundPhase.play &&
            _phase != LetterFindBySoundPhase.listen)) {
      return;
    }

    unawaited(
      _playTargetLetter(revealAfter: _phase == LetterFindBySoundPhase.listen),
    );
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
      _isSoundPlaying = false;
      _phase = LetterFindBySoundPhase.listen;
    });
    unawaited(_playTargetLetter(revealAfter: true));
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
    final progress = Positioned(
      left: 28,
      right: 28,
      top: 20,
      child: Semantics(
        label: 'Буква ${_roundIndex + 1} из ${_practiceLetters.length}',
        child: Row(
          children: List.generate(
            _practiceLetters.length,
            (progressIndex) => Expanded(
              child: Container(
                height: 6,
                margin: EdgeInsets.only(
                  right: progressIndex == _practiceLetters.length - 1 ? 0 : 6,
                ),
                decoration: BoxDecoration(
                  color: progressIndex <= _roundIndex
                      ? const Color(0xFF249B73)
                      : const Color(0x29249B73),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (_phase == LetterFindBySoundPhase.listen) {
      return TrainerSceneFill(
        child: Stack(
          fit: StackFit.expand,
          children: [
            progress,
            Center(
              child: SoundPlayButton(
                active: _isSoundPlaying,
                disabled: _isSoundPlaying,
                onPressed: _handlePlaySound,
                size: 80,
                variant: SoundPlayButtonVariant.reading,
              ),
            ),
          ],
        ),
      );
    }

    return TrainerSceneFill(
      child: Stack(
        fit: StackFit.expand,
        children: [
          LetterFieldScene(
            letters: _letters,
            disabled: _isCompleted || !_isRevealComplete,
            foundIds: _foundIds,
            onTap: _handleTap,
            presentation: LetterFieldPresentation.readingToken,
            wrongId: _wrongId,
          ),
          progress,
          Positioned(
            left: left,
            bottom: bottom,
            child: SoundPlayButton(
              active: _isSoundPlaying,
              disabled: _isCompleted || _isSoundPlaying,
              onPressed: _handlePlaySound,
              variant: SoundPlayButtonVariant.reading,
            ),
          ),
        ],
      ),
    );
  }
}
