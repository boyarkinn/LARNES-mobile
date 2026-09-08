import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/audio/flash_audio_tempo.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/audio/play_step_audio.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/types.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/example_visualization/autoplay_timeline.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/example_visualization/example_parser.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/example_visualization/example_visualization_audio.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/example_visualization/moving_bead_highlights.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/example_visualization/step_planner.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/topic_chain_flash/answer_fireworks.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/topic_chain_flash/check_answer.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_model.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_widget.dart';
import 'package:larnes_mobile/trainers/shared/instruction/load_trainer_instruction_duration.dart';
import 'package:larnes_mobile/trainers/shared/instruction/trainer_instruction_scene.dart';
import 'package:larnes_mobile/trainers/shared/instruction/trainer_instruction_typewriter.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';
import 'package:larnes_mobile/trainers/shared/trainer_timings.dart';

enum ExampleVisualizationPhase {
  instruction,
  countdown,
  play,
  solveInstruction,
  solveCountdown,
  solveFlash,
  solveAnswer,
}

List<ChainStep> exampleActionsToChainSteps(List<ExampleAction> actions) {
  return actions
      .map((action) => ChainStep(amount: action.digit, sign: action.sign))
      .toList();
}

/// Web v2: `platform/src/trainers/mental-arithmetic/example-visualization/component.tsx`
class ExampleVisualizationTrainer extends StatefulWidget {
  const ExampleVisualizationTrainer({
    super.key,
    required this.params,
    this.onComplete,
  });

  final Map<String, dynamic> params;
  final VoidCallback? onComplete;

  @override
  State<ExampleVisualizationTrainer> createState() =>
      _ExampleVisualizationTrainerState();
}

class _ExampleVisualizationTrainerState extends State<ExampleVisualizationTrainer>
    with SingleTickerProviderStateMixin {
  static const _countdownLabels = ['3', '2', '1', 'СТАРТ'];
  static const _countdownStepMs = 750;
  static const _interFlashBlankMs = 120;
  static const _wrongFeedbackMs = 450;
  static const _countdownColor = Color(0xFFDC2626);
  static const _flashColor = Color(0xFF2B59C3);
  static const _wrongColor = Color(0xFFDC2626);

  var _phase = ExampleVisualizationPhase.instruction;
  var _countdownLabel = _countdownLabels.first;
  var _instructionLength = 0;
  var _solveInstructionLength = 0;
  String? _flashLabel;
  String _answerDraft = '';
  var _hasFailedAttempt = false;
  var _isWrong = false;
  var _isCorrect = false;
  var _isSubmitting = false;
  var _fireworksKey = 0;
  var _answerSessionKey = 0;

  late ExampleStepPlan _plan;
  late List<ChainStep> _chainSteps;
  late List<AutoplayTimelineEvent> _timeline;
  late int _expectedAnswer;
  late List<RodState> _rods;
  String? _actionLabel;
  List<RodMovingBeadHighlight>? _movingBeadHighlights;
  var _timelineIndex = 0;
  var _completeCalled = false;

  Object _runToken = Object();
  final _instructionTypewriter = TrainerInstructionTypewriter();
  final _inputController = TextEditingController();
  final _inputFocus = FocusNode();
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  Timer? _countdownTimer;
  Timer? _flashTimer;
  Timer? _autoplayTimer;
  Timer? _completeTimer;
  Timer? _wrongTimer;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -8), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8, end: 8), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 8, end: -5), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -5, end: 5), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 5, end: 0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut));
    _startSession();
  }

  @override
  void didUpdateWidget(ExampleVisualizationTrainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.params != widget.params) {
      _startSession();
    }
  }

  @override
  void dispose() {
    _instructionTypewriter.cancel();
    _countdownTimer?.cancel();
    _flashTimer?.cancel();
    _autoplayTimer?.cancel();
    _completeTimer?.cancel();
    _wrongTimer?.cancel();
    _shakeController.dispose();
    _inputController.dispose();
    _inputFocus.dispose();
    unawaited(cancelStepAudio());
    unawaited(cancelExampleVisualizationAudio());
    super.dispose();
  }

  void _startSession() {
    final runToken = Object();
    _runToken = runToken;
    _instructionTypewriter.cancel();
    _countdownTimer?.cancel();
    _flashTimer?.cancel();
    _autoplayTimer?.cancel();
    _completeTimer?.cancel();
    _wrongTimer?.cancel();
    unawaited(cancelStepAudio());
    unawaited(cancelExampleVisualizationAudio());
    _inputController.clear();

    final example = widget.params['example'] as String? ?? '+2 -1';
    final totalRods = widget.params['totalRods'] as int? ?? 2;

    _plan = planExampleSteps(example, totalRods);
    _chainSteps = exampleActionsToChainSteps(_plan.actions);
    _timeline = buildAutoplayTimeline(_plan.actions.length);
    _expectedAnswer = _plan.values.last;

    setState(() {
      _phase = ExampleVisualizationPhase.instruction;
      _countdownLabel = _countdownLabels.first;
      _instructionLength = 0;
      _solveInstructionLength = 0;
      _flashLabel = null;
      _rods = cloneExampleRods(_plan.rodStates.first);
      _actionLabel = null;
      _movingBeadHighlights = null;
      _timelineIndex = 0;
      _completeCalled = false;
      _answerDraft = '';
      _hasFailedAttempt = false;
      _isWrong = false;
      _isCorrect = false;
      _isSubmitting = false;
      _fireworksKey = 0;
      _answerSessionKey += 1;
    });

    unawaited(_runInstruction(runToken));
  }

  Future<void> _runInstruction(Object runToken) async {
    final durationMs = await loadTrainerInstructionDurationMs(
      assetPath: getExampleVisualizationInstructionAudioAsset(),
      playbackRate: kExampleVisualizationInstructionPlaybackRate,
      fallbackMs: kExampleVisualizationInstructionDurationFallbackMs,
    );
    if (!mounted || !identical(runToken, _runToken)) {
      return;
    }

    _instructionTypewriter.start(
      text: kExampleVisualizationInstructionText,
      durationMs: durationMs,
      isCurrent: () => mounted && identical(runToken, _runToken),
      onLength: (length) {
        if (!mounted || !identical(runToken, _runToken)) {
          return;
        }
        setState(() => _instructionLength = length);
      },
    );

    await playExampleVisualizationInstruction();
    if (!mounted || !identical(runToken, _runToken)) {
      return;
    }

    _instructionTypewriter.cancel();
    setState(() {
      _instructionLength = kExampleVisualizationInstructionText.length;
      _phase = ExampleVisualizationPhase.countdown;
    });
    _startShowCountdown(runToken);
  }

  void _startShowCountdown(Object runToken) {
    _countdownTimer?.cancel();
    var index = 0;

    void tick() {
      if (!mounted || !identical(runToken, _runToken)) {
        return;
      }

      if (index >= _countdownLabels.length) {
        setState(() => _phase = ExampleVisualizationPhase.play);
        _restartAutoplay(runToken);
        return;
      }

      setState(() => _countdownLabel = _countdownLabels[index]);
      index += 1;
      _countdownTimer = Timer(
        const Duration(milliseconds: _countdownStepMs),
        tick,
      );
    }

    tick();
  }

  void _restartAutoplay(Object runToken) {
    _autoplayTimer?.cancel();

    final stepPauseSec =
        (widget.params['stepPauseSec'] as num?)?.toDouble() ?? 2;

    _rods = cloneExampleRods(_plan.rodStates.first);
    _actionLabel = null;
    _movingBeadHighlights = null;
    _timelineIndex = 0;

    _scheduleNext(runToken, stepPauseSec);
  }

  void _afterShowComplete(Object runToken) {
    _completeTimer?.cancel();
    _completeTimer = Timer(const Duration(milliseconds: TrainerTimings.completeDelayMs), () {
      if (!mounted || !identical(runToken, _runToken)) {
        return;
      }
      unawaited(_runSolveInstruction(runToken));
    });
  }

  Future<void> _runSolveInstruction(Object runToken) async {
    final durationMs = await loadTrainerInstructionDurationMs(
      assetPath: getExampleVisualizationSolveInstructionAudioAsset(),
      playbackRate: kExampleVisualizationInstructionPlaybackRate,
      fallbackMs: kExampleVisualizationSolveInstructionDurationFallbackMs,
    );
    if (!mounted || !identical(runToken, _runToken)) {
      return;
    }

    setState(() {
      _phase = ExampleVisualizationPhase.solveInstruction;
      _solveInstructionLength = 0;
    });

    _instructionTypewriter.start(
      text: kExampleVisualizationSolveInstructionText,
      durationMs: durationMs,
      isCurrent: () =>
          mounted &&
          identical(runToken, _runToken) &&
          _phase == ExampleVisualizationPhase.solveInstruction,
      onLength: (length) {
        if (!mounted || !identical(runToken, _runToken)) {
          return;
        }
        setState(() => _solveInstructionLength = length);
      },
    );

    await playExampleVisualizationSolveInstruction();
    if (!mounted || !identical(runToken, _runToken)) {
      return;
    }

    _instructionTypewriter.cancel();
    setState(() {
      _solveInstructionLength = kExampleVisualizationSolveInstructionText.length;
      _phase = ExampleVisualizationPhase.solveCountdown;
      _flashLabel = null;
    });
    _startSolveCountdown(runToken);
  }

  void _startSolveCountdown(Object runToken) {
    _countdownTimer?.cancel();
    var index = 0;

    void tick() {
      if (!mounted || !identical(runToken, _runToken)) {
        return;
      }

      if (index >= _countdownLabels.length) {
        setState(() {
          _flashLabel = null;
          _phase = ExampleVisualizationPhase.solveFlash;
        });
        _runSolveFlash(runToken);
        return;
      }

      setState(() => _flashLabel = _countdownLabels[index]);
      index += 1;
      _countdownTimer = Timer(
        const Duration(milliseconds: _countdownStepMs),
        tick,
      );
    }

    tick();
  }

  void _runSolveFlash(Object runToken) {
    final stepPauseSec =
        (widget.params['stepPauseSec'] as num?)?.toDouble() ?? 2;
    final pause = Duration(milliseconds: pauseMs(stepPauseSec));
    const blank = Duration(milliseconds: _interFlashBlankMs);
    final playAudio = shouldPlayFlashAudio(stepPauseSec);
    final playbackRate = flashAudioPlaybackRate(stepPauseSec);
    var index = 0;

    void goToAnswer() {
      unawaited(cancelStepAudio());
      setState(() {
        _flashLabel = null;
        _phase = ExampleVisualizationPhase.solveAnswer;
        _answerDraft = '';
        _hasFailedAttempt = false;
        _isWrong = false;
        _isCorrect = false;
        _isSubmitting = false;
      });
      _inputController.clear();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && identical(runToken, _runToken)) {
          _focusAnswerInput();
        }
      });
    }

    void showNext() {
      if (!mounted || !identical(runToken, _runToken)) {
        return;
      }

      if (index >= _chainSteps.length) {
        goToAnswer();
        return;
      }

      final step = _chainSteps[index];
      setState(() => _flashLabel = formatExampleAction(_plan.actions[index]));
      index += 1;

      void startStepTimer() {
        if (!mounted || !identical(runToken, _runToken)) {
          return;
        }

        _flashTimer = Timer(pause, () {
          if (!mounted || !identical(runToken, _runToken)) {
            return;
          }

          if (index >= _chainSteps.length) {
            goToAnswer();
            return;
          }

          setState(() => _flashLabel = null);
          _flashTimer = Timer(blank, showNext);
        });
      }

      if (playAudio) {
        unawaited(
          playStepAudio(
            step,
            playbackRate: playbackRate,
            onStarted: startStepTimer,
          ),
        );
      } else {
        startStepTimer();
      }
    }

    showNext();
  }

  void _focusAnswerInput() {
    if (!mounted) {
      return;
    }

    _inputFocus.requestFocus();
    Future<void>.delayed(const Duration(milliseconds: 120), () {
      if (mounted &&
          _phase == ExampleVisualizationPhase.solveAnswer &&
          !_isSubmitting) {
        _inputFocus.requestFocus();
      }
    });
  }

  void _replaySolve() {
    if (_isSubmitting || _phase != ExampleVisualizationPhase.solveAnswer) {
      return;
    }

    _flashTimer?.cancel();
    _countdownTimer?.cancel();
    _wrongTimer?.cancel();
    unawaited(cancelStepAudio());
    _inputController.clear();

    setState(() {
      _answerDraft = '';
      _hasFailedAttempt = false;
      _isWrong = false;
      _isCorrect = false;
      _isSubmitting = false;
      _flashLabel = null;
      _answerSessionKey += 1;
      _phase = ExampleVisualizationPhase.solveCountdown;
    });
    _startSolveCountdown(_runToken);
  }

  void _submitAnswer() {
    if (_isSubmitting || _phase != ExampleVisualizationPhase.solveAnswer) {
      return;
    }

    if (!isCorrectAnswer(_answerDraft, _expectedAnswer)) {
      setState(() {
        _isWrong = true;
        _isCorrect = false;
        _hasFailedAttempt = true;
      });
      _shakeController.forward(from: 0);
      _wrongTimer?.cancel();
      _wrongTimer = Timer(const Duration(milliseconds: _wrongFeedbackMs), () {
        if (!mounted) {
          return;
        }
        setState(() {
          _isWrong = false;
          _answerDraft = '';
        });
        _inputController.clear();
        _focusAnswerInput();
      });
      return;
    }

    setState(() {
      _isWrong = false;
      _isCorrect = true;
      _isSubmitting = true;
      _fireworksKey += 1;
    });
    _completeTimer?.cancel();
    _completeTimer = Timer(const Duration(milliseconds: TrainerTimings.completeDelayMs), () {
      if (!mounted || _completeCalled) {
        return;
      }
      _completeCalled = true;
      widget.onComplete?.call();
    });
  }

  void _scheduleNext(Object runToken, double stepPauseSec) {
    if (!mounted || !identical(runToken, _runToken)) {
      return;
    }

    if (_timelineIndex >= _timeline.length) {
      return;
    }

    final event = _timeline[_timelineIndex];
    _timelineIndex += 1;
    final playAudio = shouldPlayFlashAudio(stepPauseSec);
    final playbackRate = flashAudioPlaybackRate(stepPauseSec);

    switch (event.type) {
      case AutoplayEventType.pause:
        final step = _chainSteps[event.actionIndex!];
        setState(() {
          _movingBeadHighlights = resolveMovingBeadHighlights(
            _plan.rodStates[event.actionIndex!],
            _plan.rodStates[event.actionIndex! + 1],
          );
          _actionLabel = formatExampleAction(_plan.actions[event.actionIndex!]);
        });

        void startPauseTimer() {
          _autoplayTimer = Timer(Duration(milliseconds: pauseMs(stepPauseSec)), () {
            _scheduleNext(runToken, stepPauseSec);
          });
        }

        if (playAudio) {
          unawaited(
            playStepAudio(
              step,
              playbackRate: playbackRate,
              onStarted: startPauseTimer,
            ),
          );
        } else {
          startPauseTimer();
        }
      case AutoplayEventType.anim:
        _autoplayTimer = Timer(Duration.zero, () {
          if (!mounted || !identical(runToken, _runToken)) {
            return;
          }

          setState(() {
            _movingBeadHighlights = null;
            _rods = cloneExampleRods(_plan.rodStates[event.rodStateIndex!]);
          });

          _autoplayTimer = Timer(const Duration(milliseconds: beadAnimMs), () {
            _scheduleNext(runToken, stepPauseSec);
          });
        });
      case AutoplayEventType.done:
        unawaited(cancelStepAudio());
        setState(() {
          _actionLabel = null;
          _movingBeadHighlights = null;
        });
        _afterShowComplete(runToken);
    }
  }

  Color _fieldBorderColor({bool focused = false}) {
    if (_isWrong) {
      return _wrongColor;
    }
    if (_isCorrect) {
      return _flashColor;
    }
    if (focused) {
      return _flashColor;
    }
    return const Color(0xFFD5CFC4);
  }

  @override
  Widget build(BuildContext context) {
    final totalRods = widget.params['totalRods'] as int? ?? 2;

    return TrainerScene(
      child: switch (_phase) {
        ExampleVisualizationPhase.instruction => TrainerInstructionScene(
            length: _instructionLength,
            text: kExampleVisualizationInstructionText,
          ),
        ExampleVisualizationPhase.solveInstruction => TrainerInstructionScene(
            length: _solveInstructionLength,
            text: kExampleVisualizationSolveInstructionText,
          ),
        ExampleVisualizationPhase.countdown => Center(
            child: Text(
              _countdownLabel,
              style: const TextStyle(
                fontSize: 96,
                fontWeight: FontWeight.w700,
                color: _countdownColor,
                height: 1,
              ),
            ),
          ),
        ExampleVisualizationPhase.solveCountdown ||
        ExampleVisualizationPhase.solveFlash =>
          Center(
            child: AnimatedOpacity(
              opacity: _flashLabel == null ? 0 : 1,
              duration: const Duration(milliseconds: 150),
              child: Text(
                _flashLabel ?? ' ',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: MediaQuery.sizeOf(context).shortestSide * 0.26,
                  height: 1,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: _phase == ExampleVisualizationPhase.solveCountdown
                      ? _countdownColor
                      : _flashColor,
                ),
              ),
            ),
          ),
        ExampleVisualizationPhase.solveAnswer => Center(
            child: AnimatedBuilder(
              animation: _shakeAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(_shakeAnimation.value, 0),
                  child: child,
                );
              },
              child: ConstrainedBox(
                key: ValueKey(_answerSessionKey),
                constraints: const BoxConstraints(maxWidth: 360),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnswerFireworksBurst(
                      burstKey: _fireworksKey,
                      child: TextField(
                        controller: _inputController,
                        focusNode: _inputFocus,
                        enabled: !_isSubmitting,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^-?\d*')),
                        ],
                        textInputAction: TextInputAction.done,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: MediaQuery.sizeOf(context).shortestSide * 0.16,
                          fontWeight: FontWeight.w700,
                          height: 1,
                          color: _isWrong ? _wrongColor : _flashColor,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: _isCorrect
                              ? const Color(0xFFDCE8FF)
                              : const Color(0xFFFFFCF8),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide(
                              color: _fieldBorderColor(),
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide(
                              color: _fieldBorderColor(focused: true),
                              width: 2,
                            ),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _isWrong = false;
                            _answerDraft = value;
                          });
                        },
                        onSubmitted: (_) => _submitAnswer(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isSubmitting || _answerDraft.trim().isEmpty
                            ? null
                            : _submitAnswer,
                        child: const Text('Проверить'),
                      ),
                    ),
                    if (_hasFailedAttempt) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _isSubmitting ? null : _replaySolve,
                          child: const Text('Повторить'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ExampleVisualizationPhase.play => LayoutBuilder(
            builder: (context, constraints) {
              final maxHeight = constraints.maxHeight * 0.72;
              final maxWidth = constraints.maxWidth * 0.96;

              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 44,
                      child: Center(
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: _actionLabel == null ? 0 : 1,
                          child: Text(
                            _actionLabel ?? ' ',
                            style: const TextStyle(
                              fontFamily: 'serif',
                              fontSize: 28,
                              height: 1,
                              letterSpacing: -0.5,
                              color: Color(0xFF262626),
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: maxHeight,
                        maxWidth: maxWidth,
                      ),
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: AbacusWidget(
                          rods: _rods,
                          totalRods: totalRods,
                          movingBeadHighlights: _movingBeadHighlights,
                          raisingBeadColor: exampleVisualizationRaisingBeadColor,
                          loweringBeadColor: exampleVisualizationLoweringBeadColor,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      },
    );
  }
}
