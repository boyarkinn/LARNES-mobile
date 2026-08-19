import 'dart:async';

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/intel/fly_track/definition.dart';
import 'package:larnes_mobile/trainers/intel/fly_track/fly_track_audio.dart';
import 'package:larnes_mobile/trainers/intel/fly_track/fly_track_grid.dart';
import 'package:larnes_mobile/trainers/intel/fly_track/fly_track_phase.dart';
import 'package:larnes_mobile/trainers/intel/fly_track/model.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';

/// Web: `platform/src/trainers/intel/fly-track/component.tsx`
class FlyTrackTrainer extends StatefulWidget {
  const FlyTrackTrainer({
    super.key,
    required this.params,
    this.onComplete,
  });

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
  static const _feedbackMs = 1600;
  static const _countdownColor = Color(0xFFDC2626);
  static const _instructionColor = Color(0xFF115E59);

  late List<FlyTrackRound> _rounds;
  FlyTrackPhase _phase = FlyTrackPhase.instruction;
  String _countdownLabel = _countdownLabels.first;
  var _instructionLength = 0;
  var _roundIndex = 0;
  FlyCell? _selectedCell;
  var _replayPathIndex = 0;
  var _fireworksKey = 0;
  var _completeCalled = false;
  int? _feedbackRoundIndex;
  Object _runToken = Object();

  Timer? _instructionTypewriterTimer;
  Timer? _countdownTimer;
  Timer? _feedbackTimer;

  FlyTrackRound get _round => _rounds[_roundIndex];

  FlyCell get _visibleCell {
    if (_phase == FlyTrackPhase.replay || _phase == FlyTrackPhase.feedback) {
      return _round.path[_replayPathIndex];
    }

    return _round.start;
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
    _instructionTypewriterTimer?.cancel();
    _countdownTimer?.cancel();
    _feedbackTimer?.cancel();
    unawaited(cancelFlyTrackAudio());
    super.dispose();
  }

  bool _semanticParamsChanged(Map<String, dynamic> a, Map<String, dynamic> b) {
    return a['gridSize'] != b['gridSize'] ||
        a['rounds'] != b['rounds'] ||
        a['stepCount'] != b['stepCount'] ||
        a['stepPauseSec'] != b['stepPauseSec'];
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
    return generateFlyTrackRounds(
      GenerateFlyTrackRoundsInput(
        gridSize: _readIntParam('gridSize', kFlyTrackGridSizeDefault),
        rounds: _readIntParam('rounds', kFlyTrackRoundsDefault),
        stepCount: _readIntParam('stepCount', kFlyTrackStepCountDefault),
      ),
    );
  }

  void _startSession({required bool withInstruction}) {
    final runToken = Object();
    _runToken = runToken;
    _instructionTypewriterTimer?.cancel();
    _countdownTimer?.cancel();
    _feedbackTimer?.cancel();
    unawaited(cancelFlyTrackAudio());

    setState(() {
      _rounds = _generateRounds();
      _roundIndex = 0;
      _selectedCell = null;
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
    final durationMs = await loadFlyTrackInstructionDurationMs();
    if (!mounted || !identical(runToken, _runToken)) {
      return;
    }

    setState(() {
      _instructionLength = 0;
    });

    _startInstructionTypewriter(runToken, durationMs);

    await playFlyTrackAudio([getFlyTrackInstructionAudioAsset()]);
    if (!mounted || !identical(runToken, _runToken)) {
      return;
    }

    _instructionTypewriterTimer?.cancel();
    setState(() {
      _instructionLength = _instructionText.length;
      _phase = FlyTrackPhase.countdown;
    });
    _runCountdown(runToken);
  }

  void _startInstructionTypewriter(Object runToken, int durationMs) {
    _instructionTypewriterTimer?.cancel();
    if (_instructionText.isEmpty) {
      return;
    }

    final characterDelayMs = durationMs / _instructionText.length;
    _instructionTypewriterTimer = Timer.periodic(
      Duration(milliseconds: characterDelayMs.round().clamp(1, 1000000)),
      (_) {
        if (!mounted || !identical(runToken, _runToken)) {
          return;
        }

        if (_instructionLength >= _instructionText.length) {
          _instructionTypewriterTimer?.cancel();
          return;
        }

        setState(() => _instructionLength += 1);
      },
    );
  }

  void _runCountdown(Object runToken) {
    _countdownTimer?.cancel();
    var index = 0;

    void showNext() {
      if (!mounted || !identical(runToken, _runToken)) {
        return;
      }

      if (index >= _countdownLabels.length) {
        setState(() => _phase = FlyTrackPhase.tracking);
        unawaited(_runTracking(runToken));
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
      await playFlyTrackAudio(
        getFlyTrackMoveAudioAssets(
          step.direction,
          step.distance,
          includeFlyMoved: stepIndex == 0,
        ),
      );

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

  @override
  Widget build(BuildContext context) {
    if (_phase == FlyTrackPhase.instruction) {
      final visibleText = _instructionText.substring(
        0,
        _instructionLength.clamp(0, _instructionText.length),
      );

      return TrainerScene(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Center(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: visibleText,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                      color: _instructionColor,
                    ),
                  ),
                  const WidgetSpan(
                    alignment: PlaceholderAlignment.baseline,
                    baseline: TextBaseline.alphabetic,
                    child: _InstructionCursor(),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
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
      child: FlyTrackGrid(
        fireworksKey: _fireworksKey,
        gridSize: _readIntParam('gridSize', kFlyTrackGridSizeDefault),
        onCellSelect: _onCellSelect,
        phase: _phase,
        round: _round,
        selectedCell: _selectedCell,
        visibleCell: _visibleCell,
      ),
    );
  }
}

class _InstructionCursor extends StatefulWidget {
  const _InstructionCursor();

  @override
  State<_InstructionCursor> createState() => _InstructionCursorState();
}

class _InstructionCursorState extends State<_InstructionCursor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 3,
        height: 28,
        margin: const EdgeInsets.only(left: 4),
        color: const Color(0xFF0F766E),
      ),
    );
  }
}
