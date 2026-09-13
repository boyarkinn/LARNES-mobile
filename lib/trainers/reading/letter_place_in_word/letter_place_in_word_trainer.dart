import 'dart:async';

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/reading/letter_place_in_word/fill_gap_scene.dart';
import 'package:larnes_mobile/trainers/reading/letter_place_in_word/letter_place_in_word_audio.dart';
import 'package:larnes_mobile/trainers/reading/letter_place_in_word/place_in_word_model.dart';
import 'package:larnes_mobile/trainers/reading/reading_word_catalogs.dart';
import 'package:larnes_mobile/trainers/runtime/runtime_snapshot.dart';
import 'package:larnes_mobile/trainers/runtime/trainer_telemetry.dart';
import 'package:larnes_mobile/trainers/shared/instruction/load_trainer_instruction_duration.dart';
import 'package:larnes_mobile/trainers/shared/instruction/trainer_instruction_scene.dart';
import 'package:larnes_mobile/trainers/shared/instruction/trainer_instruction_typewriter.dart';
import 'package:larnes_mobile/trainers/shared/seeded_rng.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';

enum LetterPlaceInWordPhase { instruction, countdown, play }

class LetterPlaceInWordTrainer extends StatefulWidget {
  const LetterPlaceInWordTrainer({
    super.key,
    required this.params,
    this.onComplete,
  });

  final Map<String, dynamic> params;
  final VoidCallback? onComplete;

  @override
  State<LetterPlaceInWordTrainer> createState() =>
      _LetterPlaceInWordTrainerState();
}

class _LetterPlaceInWordTrainerState extends State<LetterPlaceInWordTrainer> {
  static const _countdownLabels = ['3', '2', '1', 'СТАРТ'];
  static const _countdownStepMs = 750;

  late final int _layoutSalt;
  late final List<String> _practiceLetters;
  late final List<FillGapTask> _tasks;
  late final List<LetterPoolTile> _poolTiles;

  final _instructionTypewriter = TrainerInstructionTypewriter();
  LetterPlaceInWordPhase _phase = LetterPlaceInWordPhase.instruction;
  String _countdownLabel = _countdownLabels.first;
  int _instructionLength = 0;
  Timer? _countdownTimer;
  final Object _runToken = Object();

  @override
  void initState() {
    super.initState();
    _layoutSalt = createLayoutSalt();
    _practiceLetters = parseFillGapPracticeLetters(
      widget.params['practiceLetters'] as String? ?? 'А',
    );
    final entityCount = widget.params['entityCount'] as int? ?? 1;
    final distractorCount = widget.params['distractorCount'] as int? ?? 3;
    final letterCase = widget.params['letterCase'] as String? ?? 'upper';
    final wordCase = widget.params['wordCase'] as String? ?? 'upper';
    final seed = buildPlaceInWordRoundSeed([
      entityCount,
      widget.params['practiceLetters'] ?? 'А',
      distractorCount,
      wordCase,
      letterCase,
      _layoutSalt,
    ]);
    final snapshotSeed = readTrainerSnapshotSeed(
      'letter-place-in-word',
      widget.params,
    );
    final snapshotRng = snapshotSeed == null
        ? null
        : TrainerSnapshotRandom(snapshotSeed);
    _tasks = buildFillGapTasks(
      entityCount: entityCount,
      letterCase: letterCase,
      practiceLetters: _practiceLetters,
      seed: snapshotRng == null ? seed : null,
      random: snapshotRng?.nextDouble,
      wordCase: wordCase,
    );
    final poolRng = snapshotRng?.nextDouble ?? createSeededRng(seed + 17);
    _poolTiles = buildLetterPoolTiles(
      distractorCount: distractorCount,
      letterCase: letterCase,
      rng: poolRng,
      tasks: _tasks,
    );
    unawaited(_runInstruction(_runToken));
  }

  @override
  void dispose() {
    _instructionTypewriter.cancel();
    _countdownTimer?.cancel();
    unawaited(cancelLetterPlaceInWordAudio());
    super.dispose();
  }

  Future<void> _runInstruction(Object runToken) async {
    final durationMs = await loadTrainerInstructionDurationMs(
      assetPath: getLetterPlaceInWordInstructionAudioAsset(),
      playbackRate: kLetterPlaceInWordInstructionPlaybackRate,
      fallbackMs: kLetterPlaceInWordInstructionDurationFallbackMs,
    );
    if (!mounted || !identical(runToken, _runToken)) {
      return;
    }

    _instructionTypewriter.start(
      text: kLetterPlaceInWordInstructionText,
      durationMs: durationMs,
      isCurrent: () => mounted && identical(runToken, _runToken),
      onLength: (length) {
        if (mounted && identical(runToken, _runToken)) {
          setState(() => _instructionLength = length);
        }
      },
    );

    await playLetterPlaceInWordInstruction();
    if (!mounted || !identical(runToken, _runToken)) {
      return;
    }

    _instructionTypewriter.cancel();
    setState(() {
      _instructionLength = kLetterPlaceInWordInstructionText.length;
      _phase = LetterPlaceInWordPhase.countdown;
    });
    _runCountdown(runToken);
  }

  void _runCountdown(Object runToken) {
    var index = 0;

    void advance() {
      if (!mounted || !identical(runToken, _runToken)) {
        return;
      }
      if (index >= _countdownLabels.length) {
        setState(() => _phase = LetterPlaceInWordPhase.play);
        return;
      }
      setState(() => _countdownLabel = _countdownLabels[index]);
      index += 1;
      _countdownTimer = Timer(
        const Duration(milliseconds: _countdownStepMs),
        advance,
      );
    }

    advance();
  }

  @override
  Widget build(BuildContext context) {
    if (_phase == LetterPlaceInWordPhase.instruction) {
      return TrainerInstructionScene(
        length: _instructionLength,
        text: kLetterPlaceInWordInstructionText,
      );
    }

    if (_phase == LetterPlaceInWordPhase.countdown) {
      return TrainerScene(
        child: Center(
          child: Text(
            _countdownLabel,
            style: const TextStyle(
              color: Color(0xFF2F7D59),
              fontSize: 96,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
        ),
      );
    }

    return TrainerScene(
      child: FillGapScene(
        onComplete: () => widget.onComplete?.call(),
        onCorrect: (completedWords) {
          TrainerTelemetryScope.maybeOf(context)?.interaction(
            correct: true,
            progressCurrent: completedWords,
            progressTotal: _tasks.length,
          );
        },
        onWrong: (completedWords) {
          TrainerTelemetryScope.maybeOf(context)?.interaction(
            correct: false,
            errorCode: 'wrong_letter',
            progressCurrent: completedWords,
            progressTotal: _tasks.length,
          );
        },
        poolTiles: _poolTiles,
        tasks: _tasks,
      ),
    );
  }
}
