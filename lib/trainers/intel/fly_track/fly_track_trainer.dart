import 'dart:async';

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/intel/fly_track/definition.dart';
import 'package:larnes_mobile/trainers/intel/fly_track/fly_track_audio.dart';
import 'package:larnes_mobile/trainers/intel/fly_track/fly_track_grid.dart';
import 'package:larnes_mobile/trainers/intel/fly_track/fly_track_phase.dart';
import 'package:larnes_mobile/trainers/intel/fly_track/model.dart';
import 'package:larnes_mobile/trainers/runtime/runtime_snapshot.dart';
import 'package:larnes_mobile/trainers/shared/instruction/load_trainer_instruction_duration.dart';
import 'package:larnes_mobile/trainers/shared/instruction/trainer_instruction_scene.dart';
import 'package:larnes_mobile/trainers/shared/instruction/trainer_instruction_typewriter.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';

/// Web: `platform/src/trainers/intel/fly-track/component.tsx`
class FlyTrackTrainer extends StatefulWidget {
  const FlyTrackTrainer({super.key, required this.params, this.onComplete});

  final Map<String, dynamic> params;
  final VoidCallback? onComplete;

  @override
  State<FlyTrackTrainer> createState() => _FlyTrackTrainerState();
}

class _FlyTrackTrainerState extends State<FlyTrackTrainer> {
  static const _instructionText =
      'Отследи движение мухи и нажми на поле, где она приземлилась.';
  static const _countdownLabels = ['3', '2', '1', 'СТАРТ'];
  static const _countdownStepMs = 750;
  static const _memorizeStartMs = 1500;
  static const _flyDepartureDelayMs = 280;
  static const _flyDepartureMs = 600;
  static const _replayMoveMs = 420;
  static const _feedbackMs = 1600;
  static const _countdownColor = Color(0xFF2B59C3);

  late List<FlyTrackRound> _rounds;
  FlyTrackPhase _phase = FlyTrackPhase.instruction;
  String _countdownLabel = _countdownLabels.first;
  var _instructionLength = 0;
  var _roundIndex = 0;
  FlyCell? _selectedCell;
  Offset? _departingFlyPosition;
  var _departingFlyOpacity = 1.0;
  var _replayPathIndex = 0;
  var _fireworksKey = 0;
  var _completeCalled = false;
  int? _feedbackRoundIndex;
  Object _runToken = Object();

  final _instructionTypewriter = TrainerInstructionTypewriter();
  Timer? _countdownTimer;
  Timer? _feedbackTimer;

  FlyTrackRound get _round => _rounds[_roundIndex];

  FlyCell? get _visibleCell {
    if (_phase == FlyTrackPhase.replay || _phase == FlyTrackPhase.feedback) {
      return _round.path[_replayPathIndex];
    }

    if (_phase == FlyTrackPhase.memorize) {
      return _round.start;
    }

    return null;
  }

  Offset? get _visiblePosition {
    if (_phase == FlyTrackPhase.tracking) {
      return _departingFlyPosition;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _rounds = _generateRounds();
    _startSession(withInstruction: true);
  }

  @override
  void didUpdateWidget(FlyTrackTrainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_semanticParamsChanged(oldWidget.params, widget.params)) {
      _startSession(withInstruction: true);
    }
  }

  @override
  void dispose() {
    _instructionTypewriter.cancel();
    _countdownTimer?.cancel();
    _feedbackTimer?.cancel();
    unawaited(cancelFlyTrackAudio());
    super.dispose();
  }

  bool _semanticParamsChanged(Map<String, dynamic> a, Map<String, dynamic> b) {
    return a['gridSize'] != b['gridSize'] ||
        a['rounds'] != b['rounds'] ||
        a['stepCount'] != b['stepCount'] ||
        a['stepPauseSec'] != b['stepPauseSec'] ||
        readTrainerSnapshotSeed('fly-track', a) !=
            readTrainerSnapshotSeed('fly-track', b);
  }

  int _readIntParam(String key, int fallback) {
    final value = widget.params[key];
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse('$value') ?? fallback;
  }

  double _readDoubleParam(String key, double fallback) {
    final value = widget.params[key];
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse('$value') ?? fallback;
  }

  List<FlyTrackRound> _generateRounds() {
    final snapshotSeed = readTrainerSnapshotSeed('fly-track', widget.params);
    return generateFlyTrackRounds(
      GenerateFlyTrackRoundsInput(
        gridSize: _readIntParam('gridSize', kFlyTrackGridSizeDefault),
        random: snapshotSeed == null
            ? null
            : TrainerSnapshotRandom(snapshotSeed).nextDouble,
        rounds: _readIntParam('rounds', kFlyTrackRoundsDefault),
        stepCount: _readIntParam('stepCount', kFlyTrackStepCountDefault),
      ),
    );
  }

  void _startSession({required bool withInstruction}) {
    final runToken = Object();
    _runToken = runToken;
    _instructionTypewriter.cancel();
    _countdownTimer?.cancel();
    _feedbackTimer?.cancel();
    unawaited(cancelFlyTrackAudio());

    setState(() {
      _rounds = _generateRounds();
      _roundIndex = 0;
      _selectedCell = null;
      _departingFlyPosition = null;
      _departingFlyOpacity = 1;
      _replayPathIndex = 0;
      _fireworksKey = 0;
      _completeCalled = false;
      _feedbackRoundIndex = null;
      _instructionLength = 0;
      _countdownLabel = _countdownLabels.first;
      _phase = withInstruction
          ? FlyTrackPhase.instruction
          : FlyTrackPhase.countdown;
    });

    if (withInstruction) {
      unawaited(_runInstruction(runToken));
    } else {
      _runCountdown(runToken);
    }
  }

  Future<void> _runInstruction(Object runToken) async {
    final durationMs = await loadTrainerInstructionDurationMs(
      assetPath: getFlyTrackInstructionAudioAsset(),
      playbackRate: kFlyTrackAudioPlaybackRate,
      fallbackMs: kFlyTrackInstructionDurationFallbackMs,
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

    await playFlyTrackAudio([getFlyTrackInstructionAudioAsset()]);
    if (!mounted || !identical(runToken, _runToken)) {
      return;
    }

    _instructionTypewriter.cancel();
    setState(() {
      _instructionLength = _instructionText.length;
      _phase = FlyTrackPhase.countdown;
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
        setState(() => _phase = FlyTrackPhase.memorize);
        _countdownTimer = Timer(
          const Duration(milliseconds: _memorizeStartMs),
          () {
            if (!mounted || !identical(runToken, _runToken)) {
              return;
            }
            setState(() {
              _departingFlyPosition = Offset(
                _round.start.column.toDouble(),
                _round.start.row.toDouble(),
              );
              _departingFlyOpacity = 1;
              _phase = FlyTrackPhase.tracking;
            });
            unawaited(_runTracking(runToken));
          },
        );
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

  Future<void> _runTracking(Object runToken) async {
    final stepPauseSec = _readDoubleParam(
      'stepPauseSec',
      kFlyTrackStepPauseSecDefault,
    );
    final round = _round;

    for (var stepIndex = 0; stepIndex < round.steps.length; stepIndex++) {
      if (!mounted || !identical(runToken, _runToken)) {
        return;
      }

      final step = round.steps[stepIndex];
      final audioFuture = playFlyTrackAudio(
        getFlyTrackMoveAudioAssets(
          step.direction,
          step.distance,
          includeFlyMoved: stepIndex == 0,
        ),
      );

      if (stepIndex == 0) {
        await Future<void>.delayed(
          const Duration(milliseconds: _flyDepartureDelayMs),
        );
        if (!mounted || !identical(runToken, _runToken)) {
          return;
        }

        final firstTarget = round.path[1];
        setState(() {
          _departingFlyPosition = Offset(
            round.start.column +
                _sign(firstTarget.column - round.start.column) * 0.72,
            round.start.row + _sign(firstTarget.row - round.start.row) * 0.72,
          );
          _departingFlyOpacity = 0;
        });
        await Future.wait([
          audioFuture,
          Future<void>.delayed(const Duration(milliseconds: _flyDepartureMs)),
        ]);
        if (mounted && identical(runToken, _runToken)) {
          setState(() => _departingFlyPosition = null);
        }
      } else {
        await audioFuture;
      }

      if (!mounted || !identical(runToken, _runToken)) {
        return;
      }

      if (stepIndex < round.steps.length - 1) {
        await Future<void>.delayed(
          Duration(milliseconds: (stepPauseSec * 1000).round()),
        );
      }
    }

    if (!mounted || !identical(runToken, _runToken)) {
      return;
    }

    setState(() => _phase = FlyTrackPhase.answer);
    unawaited(playFlyTrackAudio([getFlyTrackAnswerAudioAsset()]));
  }

  void _onCellSelect(FlyCell cell) {
    if (_phase != FlyTrackPhase.answer) {
      return;
    }

    setState(() {
      _selectedCell = cell;
      _replayPathIndex = 0;
      _phase = FlyTrackPhase.replay;
    });

    unawaited(_runReplay(_runToken));
  }

  Future<void> _runReplay(Object runToken) async {
    final round = _round;

    setState(() => _replayPathIndex = 0);

    for (var stepIndex = 0; stepIndex < round.steps.length; stepIndex++) {
      if (!mounted || !identical(runToken, _runToken)) {
        return;
      }

      final step = round.steps[stepIndex];
      await playFlyTrackAudio(
        getFlyTrackReplayAudioAssets(step.direction, step.distance),
      );

      if (!mounted || !identical(runToken, _runToken)) {
        return;
      }

      setState(() => _replayPathIndex = stepIndex + 1);
      await Future<void>.delayed(const Duration(milliseconds: _replayMoveMs));
    }

    if (!mounted || !identical(runToken, _runToken)) {
      return;
    }

    setState(() => _phase = FlyTrackPhase.feedback);
    _runFeedback(runToken);
  }

  void _runFeedback(Object runToken) {
    _feedbackTimer?.cancel();

    if (_feedbackRoundIndex != _roundIndex) {
      _feedbackRoundIndex = _roundIndex;
      if (_sameCell(_selectedCell, _round.finish)) {
        setState(() => _fireworksKey += 1);
      }
    }

    _feedbackTimer = Timer(const Duration(milliseconds: _feedbackMs), () {
      if (!mounted || !identical(runToken, _runToken)) {
        return;
      }

      if (_roundIndex + 1 < _rounds.length) {
        setState(() {
          _selectedCell = null;
          _replayPathIndex = 0;
          _roundIndex += 1;
          _phase = FlyTrackPhase.countdown;
        });
        _runCountdown(runToken);
        return;
      }

      if (!_completeCalled) {
        _completeCalled = true;
        widget.onComplete?.call();
      }
    });
  }

  bool _sameCell(FlyCell? left, FlyCell? right) {
    if (left == null || right == null) {
      return false;
    }

    return left.row == right.row && left.column == right.column;
  }

  double _sign(int value) => value == 0
      ? 0
      : value.isNegative
      ? -1
      : 1;

  @override
  Widget build(BuildContext context) {
    if (_phase == FlyTrackPhase.instruction) {
      return TrainerInstructionScene(
        length: _instructionLength,
        text: _instructionText,
      );
    }

    if (_phase == FlyTrackPhase.countdown) {
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

    return TrainerSceneFill(
      child: Stack(
        children: [
          FlyTrackGrid(
            fireworksKey: _fireworksKey,
            gridSize: _readIntParam('gridSize', kFlyTrackGridSizeDefault),
            onCellSelect: _onCellSelect,
            phase: _phase,
            replayPathIndex: _replayPathIndex,
            round: _round,
            selectedCell: _selectedCell,
            flyOpacity: _phase == FlyTrackPhase.tracking
                ? _departingFlyOpacity
                : 1,
            visibleCell: _visibleCell,
            visiblePosition: _visiblePosition,
          ),
          if (_rounds.length > 1)
            Positioned(
              left: 0,
              right: 0,
              top: 16,
              child: IgnorePointer(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _rounds.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: index <= _roundIndex
                            ? const Color(0xFF2B59C3)
                            : const Color(0x242B59C3),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
