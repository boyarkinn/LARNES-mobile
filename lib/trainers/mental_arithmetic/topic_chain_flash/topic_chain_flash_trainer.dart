import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/audio/clip_player.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/audio/flash_audio_tempo.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/audio/instruction_audio.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/audio/play_step_audio.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/generate.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/types.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/topic_chain_flash/answer_fireworks.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/topic_chain_flash/check_answer.dart';
import 'package:larnes_mobile/trainers/runtime/runtime_snapshot.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';

/// Web v2: `platform/src/trainers/mental-arithmetic/topic-chain-flash/component.tsx`
class TopicChainFlashTrainer extends StatefulWidget {
  const TopicChainFlashTrainer({
    super.key,
    required this.params,
    this.onComplete,
  });

  final Map<String, dynamic> params;
  final VoidCallback? onComplete;

  @override
  State<TopicChainFlashTrainer> createState() => _TopicChainFlashTrainerState();
}

enum _Phase { boot, instruction, countdown, flash, answer, error }

class _TopicChainFlashTrainerState extends State<TopicChainFlashTrainer>
    with SingleTickerProviderStateMixin {
  static const _wrongFeedbackMs = 450;

  /// Пауза после верного ответа — успеть увидеть feedback.
  static const _successFeedbackMs = 900;
  static const _wrongColor = Color(0xFFDC2626);
  static const _successColor = Color(0xFF16A34A);
  static const _okSoft = Color(0xB8DCFCE7);
  static const _objectColor = Color(0xFFE45B4E);
  static const _objectDeep = Color(0xFFB93F38);

  /// Пауза между вспышками — иначе подряд одинаковые шаги (+1 +1) сливаются в одно.
  static const _interFlashBlankMs = 120;

  /// Обратный отсчёт перед каждым примером — ребёнок успевает взять абакус.
  static const _countdownStepMs = 750;
  static const _countdownLabels = ['3', '2', '1', 'СТАРТ'];
  static const _flashColor = _objectColor;

  _Phase _phase = _Phase.boot;
  Chain? _chain;
  var _exampleIndex = 0;
  String? _flashLabel;
  var _flashStepIndex = -1;
  String _answerDraft = '';
  bool _isWrong = false;
  bool _isCorrect = false;
  var _fireworksKey = 0;
  bool _isSubmitting = false;
  String? _errorMessage;
  bool _completeCalled = false;
  Object _runToken = Object();
  Timer? _flashTimer;
  Timer? _countdownTimer;
  Timer? _instructionTimer;
  Timer? _wrongTimer;
  Timer? _completeTimer;
  final _inputController = TextEditingController();
  final _inputFocus = FocusNode();
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  int get _totalExamples =>
      _readIntParam(widget.params['exampleCount'], 1).clamp(1, 10);

  Chain? _fixedChain(int index) {
    final payload = readTrainerRuntimeSnapshot(
      'topic-chain-flash',
      widget.params,
    );
    final rawChains = payload?['chains'];
    if (rawChains is! List || index < 0 || index >= rawChains.length) {
      return null;
    }
    final rawChain = rawChains[index];
    if (rawChain is! Map) {
      return null;
    }
    final map = Map<String, dynamic>.from(rawChain);
    final rawSteps = map['steps'];
    final rawIntermediates = map['intermediates'];
    if (rawSteps is! List || rawIntermediates is! List) {
      return null;
    }
    return Chain(
      answer: (map['answer'] as num).toInt(),
      intermediates: rawIntermediates
          .map((value) => (value as num).toInt())
          .toList(),
      steps: rawSteps.map((raw) {
        final step = Map<String, dynamic>.from(raw as Map);
        return ChainStep(
          amount: (step['amount'] as num).toInt(),
          sign: step['sign'] as String,
        );
      }).toList(),
      topicId: map['topicId'] as String,
    );
  }

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _wrongFeedbackMs),
    );
    _shakeAnimation =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 0, end: -8), weight: 1),
          TweenSequenceItem(tween: Tween(begin: -8, end: 8), weight: 1),
          TweenSequenceItem(tween: Tween(begin: 8, end: -5), weight: 1),
          TweenSequenceItem(tween: Tween(begin: -5, end: 5), weight: 1),
          TweenSequenceItem(tween: Tween(begin: 5, end: 0), weight: 1),
        ]).animate(
          CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
        );
    _startSession();
  }

  @override
  void didUpdateWidget(TopicChainFlashTrainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_semanticParamsChanged(oldWidget.params, widget.params)) {
      _startSession();
    }
  }

  @override
  void dispose() {
    _flashTimer?.cancel();
    _countdownTimer?.cancel();
    _instructionTimer?.cancel();
    _wrongTimer?.cancel();
    _completeTimer?.cancel();
    unawaited(cancelStepAudio());
    _shakeController.dispose();
    _inputController.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  bool _semanticParamsChanged(Map<String, dynamic> a, Map<String, dynamic> b) {
    return a['topicId'] != b['topicId'] ||
        a['actionCount'] != b['actionCount'] ||
        a['exampleCount'] != b['exampleCount'] ||
        a['solveMode'] != b['solveMode'] ||
        a['stepPauseSec'] != b['stepPauseSec'];
  }

  void _startSession() {
    _completeCalled = false;
    final runToken = Object();
    _runToken = runToken;
    unawaited(_runInstruction(runToken));
  }

  Future<void> _runInstruction(Object runToken) async {
    _flashTimer?.cancel();
    _countdownTimer?.cancel();
    _instructionTimer?.cancel();
    _wrongTimer?.cancel();
    _completeTimer?.cancel();
    unawaited(cancelStepAudio());

    final solveMode = normalizeSolveMode(widget.params['solveMode']);
    final stepPauseSec =
        (widget.params['stepPauseSec'] as num?)?.toDouble() ??
        double.tryParse('${widget.params['stepPauseSec'] ?? ''}') ??
        1;

    if (!mounted || !identical(runToken, _runToken)) {
      return;
    }

    setState(() {
      _chain = null;
      _exampleIndex = 0;
      _flashLabel = solveModeInstructionLabel(solveMode);
      _flashStepIndex = -1;
      _errorMessage = null;
      _phase = _Phase.instruction;
      _answerDraft = '';
      _isWrong = false;
      _isCorrect = false;
      _isSubmitting = false;
    });

    if (shouldPlayFlashAudio(stepPauseSec)) {
      await getSharedClipPlayer().play([
        getInstructionAudioAsset(solveMode),
      ], playbackRate: kInstructionPlaybackRate);
      if (!mounted || !identical(runToken, _runToken)) {
        return;
      }
      _startExample(0, resetCompleteFlag: true);
      return;
    }

    final done = Completer<void>();
    _instructionTimer = Timer(
      const Duration(milliseconds: kInstructionSilentMs),
      () {
        if (!done.isCompleted) {
          done.complete();
        }
      },
    );
    await done.future;
    if (!mounted || !identical(runToken, _runToken)) {
      return;
    }
    _startExample(0, resetCompleteFlag: true);
  }

  void _startExample(int nextIndex, {bool resetCompleteFlag = false}) {
    _flashTimer?.cancel();
    _countdownTimer?.cancel();
    _instructionTimer?.cancel();
    _wrongTimer?.cancel();
    _completeTimer?.cancel();
    unawaited(cancelStepAudio());
    if (resetCompleteFlag) {
      _completeCalled = false;
    }
    _inputController.clear();
    _answerDraft = '';
    _isWrong = false;
    _isCorrect = false;
    _isSubmitting = false;
    _flashLabel = null;
    _flashStepIndex = -1;
    _errorMessage = null;
    _exampleIndex = nextIndex;

    final runToken = Object();
    _runToken = runToken;

    try {
      final chain =
          _fixedChain(nextIndex) ??
          generateChain(
            GenerateConfig(
              topicId: widget.params['topicId'] as String? ?? 'simple-1',
              actionCount: _readIntParam(widget.params['actionCount'], 5),
              signMode: 'mix',
            ),
          );

      if (!mounted || !identical(runToken, _runToken)) {
        return;
      }

      setState(() {
        _chain = chain;
        _exampleIndex = nextIndex;
        _phase = _Phase.countdown;
      });
      _runCountdown(runToken, chain);
    } on GenerateNotImplementedError {
      setState(() {
        _chain = null;
        _phase = _Phase.error;
        _errorMessage = 'Тема пока недоступна.';
      });
    } on GenerateFailedError {
      setState(() {
        _chain = null;
        _phase = _Phase.error;
        _errorMessage =
            'Не удалось собрать цепочку. Попробуйте другие параметры.';
      });
    } catch (_) {
      setState(() {
        _chain = null;
        _phase = _Phase.error;
        _errorMessage = 'Ошибка генерации.';
      });
    }
  }

  void _focusAnswerInput() {
    if (!mounted) {
      return;
    }

    _inputFocus.requestFocus();
    Future<void>.delayed(const Duration(milliseconds: 120), () {
      if (mounted && _phase == _Phase.answer && !_isSubmitting) {
        _inputFocus.requestFocus();
      }
    });
  }

  void _runCountdown(Object runToken, Chain chain) {
    const step = Duration(milliseconds: _countdownStepMs);
    var index = 0;

    void showNext() {
      if (!mounted || !identical(runToken, _runToken)) {
        return;
      }

      if (index >= _countdownLabels.length) {
        setState(() {
          _flashLabel = null;
          _flashStepIndex = -1;
          _phase = _Phase.flash;
        });
        _runFlash(runToken, chain);
        return;
      }

      final label = _countdownLabels[index];
      index += 1;
      setState(() => _flashLabel = label);
      _countdownTimer = Timer(step, showNext);
    }

    showNext();
  }

  void _runFlash(Object runToken, Chain chain) {
    final stepPauseSec =
        (widget.params['stepPauseSec'] as num?)?.toDouble() ??
        double.tryParse('${widget.params['stepPauseSec'] ?? ''}') ??
        1;
    final pause = Duration(milliseconds: (stepPauseSec * 1000).round());
    const blank = Duration(milliseconds: _interFlashBlankMs);
    final playAudio = shouldPlayFlashAudio(stepPauseSec);
    final playbackRate = flashAudioPlaybackRate(stepPauseSec);
    var index = 0;

    void goToAnswer() {
      unawaited(cancelStepAudio());
      setState(() {
        _flashLabel = null;
        _flashStepIndex = -1;
        _phase = _Phase.answer;
      });
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

      if (index >= chain.steps.length) {
        goToAnswer();
        return;
      }

      final step = chain.steps[index];
      setState(() {
        _flashLabel = formatChainStep(step);
        _flashStepIndex = index;
      });
      index += 1;

      void startStepTimer() {
        if (!mounted || !identical(runToken, _runToken)) {
          return;
        }

        _flashTimer = Timer(pause, () {
          if (!mounted || !identical(runToken, _runToken)) {
            return;
          }

          if (index >= chain.steps.length) {
            goToAnswer();
            return;
          }

          // Blank между шагами — иначе одинаковые лейблы не отличить.
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

  void _replayExample() {
    final chain = _chain;
    if (chain == null || _isSubmitting || _phase != _Phase.answer) {
      return;
    }

    _flashTimer?.cancel();
    _countdownTimer?.cancel();
    _instructionTimer?.cancel();
    _wrongTimer?.cancel();
    _completeTimer?.cancel();
    unawaited(cancelStepAudio());
    _inputController.clear();

    final runToken = Object();
    _runToken = runToken;

    setState(() {
      _answerDraft = '';
      _isWrong = false;
      _isCorrect = false;
      _isSubmitting = false;
      _flashLabel = null;
      _flashStepIndex = -1;
      _phase = _Phase.countdown;
    });
    _runCountdown(runToken, chain);
  }

  static int _readIntParam(Object? value, int fallback) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.round();
    }
    if (value is String) {
      return int.tryParse(value) ?? fallback;
    }
    return fallback;
  }

  void _submit() {
    final chain = _chain;
    if (chain == null || _isSubmitting || _phase != _Phase.answer) {
      return;
    }

    if (!isCorrectAnswer(_answerDraft, chain.answer)) {
      setState(() {
        _isWrong = true;
        _isCorrect = false;
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
          _inputController.clear();
        });
        _focusAnswerInput();
      });
      return;
    }

    setState(() {
      _isWrong = false;
      _isCorrect = true;
      _isSubmitting = true;
      if (_exampleIndex + 1 >= _totalExamples) {
        _fireworksKey += 1;
      }
    });
    _completeTimer?.cancel();
    _completeTimer = Timer(
      const Duration(milliseconds: _successFeedbackMs),
      () {
        if (!mounted) {
          return;
        }

        if (_exampleIndex + 1 < _totalExamples) {
          _startExample(_exampleIndex + 1);
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

  Color _fieldBorderColor({bool focused = false}) {
    if (_isWrong) {
      return _wrongColor;
    }
    if (_isCorrect) {
      return _successColor;
    }
    if (focused) {
      return _objectColor.withValues(alpha: 0.55);
    }
    return const Color(0x337759D6);
  }

  Widget _progressDots() {
    final total = _totalExamples;
    if (total <= 1) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: 0,
      right: 0,
      bottom: 24,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var index = 0; index < total; index++) ...[
            if (index > 0) const SizedBox(width: 8),
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: index < _exampleIndex
                    ? _objectColor
                    : const Color(0x247759D6),
                border: index < _exampleIndex
                    ? null
                    : Border.all(color: const Color(0x55E45B4E)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TrainerScene(
      child: Stack(
        children: [
          if (_phase == _Phase.flash && _flashLabel != null)
            Positioned.fill(
              child: IgnorePointer(
                child: _RouteEnergyPulse(
                  pulseKey: _flashStepIndex,
                  reduceMotion: MediaQuery.disableAnimationsOf(context),
                ),
              ),
            ),
          Center(
            child: switch (_phase) {
              _Phase.error => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  _errorMessage ?? 'Ошибка',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF57534E),
                  ),
                ),
              ),
              _Phase.boot ||
              _Phase.instruction ||
              _Phase.countdown ||
              _Phase.flash => AnimatedSwitcher(
                duration: Duration(
                  milliseconds: MediaQuery.disableAnimationsOf(context)
                      ? 0
                      : 120,
                ),
                child: _FlashValueStage(
                  key: ValueKey(
                    '${_phase.name}-${_flashLabel ?? 'blank'}-$_flashStepIndex',
                  ),
                  actionCount: _chain?.steps.length ?? 0,
                  actionIndex: _flashStepIndex,
                  flashMode: _phase == _Phase.flash,
                  instructionMode: _phase == _Phase.instruction,
                  label: _flashLabel,
                  reduceMotion: MediaQuery.disableAnimationsOf(context),
                ),
              ),
              _Phase.answer => AnimatedBuilder(
                animation: _shakeAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(_shakeAnimation.value, 0),
                    child: child,
                  );
                },
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnswerFireworksBurst(
                        burstKey: _fireworksKey,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    (_isCorrect
                                            ? _successColor
                                            : const Color(0xFF7759D6))
                                        .withValues(alpha: 0.1),
                                blurRadius: 38,
                                offset: const Offset(0, 14),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _inputController,
                            focusNode: _inputFocus,
                            enabled: !_isSubmitting,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            autofocus: true,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize:
                                  MediaQuery.sizeOf(context).shortestSide *
                                  0.14,
                              height: 1,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                              color: _isWrong
                                  ? _wrongColor
                                  : _isCorrect
                                  ? _successColor
                                  : _objectDeep,
                            ),
                            cursorColor: _isWrong ? _wrongColor : _flashColor,
                            decoration: InputDecoration(
                              hintText: '?',
                              hintStyle: TextStyle(
                                color: _objectColor.withValues(alpha: 0.28),
                              ),
                              filled: true,
                              fillColor: _isCorrect
                                  ? _okSoft
                                  : const Color(0x75FFFFFF),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 20,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide(
                                  width: 2,
                                  color: _fieldBorderColor(),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide(
                                  width: 2,
                                  color: _fieldBorderColor(),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide(
                                  width: 2,
                                  color: _fieldBorderColor(focused: true),
                                ),
                              ),
                              disabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide(
                                  width: 2,
                                  color: _fieldBorderColor(),
                                ),
                              ),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _isWrong = false;
                                _answerDraft = value;
                              });
                            },
                            onSubmitted: (_) => _submit(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed:
                              _isSubmitting || _answerDraft.trim().isEmpty
                              ? null
                              : _submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: _objectColor,
                            disabledBackgroundColor: _objectColor.withValues(
                              alpha: 0.15,
                            ),
                            disabledForegroundColor: _objectDeep.withValues(
                              alpha: 0.35,
                            ),
                            foregroundColor: Colors.white,
                            elevation: 3,
                            shadowColor: _objectDeep.withValues(alpha: 0.24),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: const Text(
                            'Проверить',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isSubmitting ? null : _replayExample,
                          style: OutlinedButton.styleFrom(
                            backgroundColor: const Color(0x59FFFFFF),
                            foregroundColor: const Color(0xFF5F43BA),
                            side: const BorderSide(color: Color(0x337759D6)),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          icon: const Icon(Icons.replay_rounded, size: 21),
                          label: const Text(
                            'Повторить цепочку',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            },
          ),
          _progressDots(),
        ],
      ),
    );
  }
}

class _FlashValueStage extends StatelessWidget {
  const _FlashValueStage({
    super.key,
    required this.actionCount,
    required this.actionIndex,
    required this.flashMode,
    required this.instructionMode,
    required this.label,
    required this.reduceMotion,
  });

  final int actionCount;
  final int actionIndex;
  final bool flashMode;
  final bool instructionMode;
  final String? label;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final value = label;
    if (value == null) {
      return const SizedBox(width: 240, height: 180);
    }

    final negative = flashMode && value.trimLeft().startsWith('-');
    final fontSize =
        MediaQuery.sizeOf(context).shortestSide *
        (instructionMode ? 0.12 : 0.26);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: reduceMotion ? 0 : 260),
          curve: Curves.easeOutCubic,
          builder: (context, progress, child) {
            final offset = flashMode
                ? (negative ? -42.0 : 42.0) * (1 - progress)
                : 20.0 * (1 - progress);
            return Opacity(
              opacity: progress.clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(0, offset),
                child: Transform.scale(
                  scale: 0.94 + 0.06 * progress,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (flashMode && !reduceMotion)
                        SizedBox(
                          key: const ValueKey('topic-chain-light-wave-burst'),
                          width: fontSize * 1.75,
                          height: fontSize * 1.75,
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: 1),
                            duration: const Duration(milliseconds: 460),
                            curve: Curves.easeOutCubic,
                            builder: (context, waveProgress, child) =>
                                CustomPaint(
                                  painter: _LightWaveBurstPainter(waveProgress),
                                ),
                          ),
                        ),
                      Text(
                        value,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _TopicChainFlashTrainerState._objectColor,
                          fontWeight: FontWeight.w700,
                          fontSize: fontSize,
                          height: 1,
                          fontFeatures: instructionMode
                              ? null
                              : const [FontFeature.tabularFigures()],
                          shadows: const [
                            Shadow(
                              color: Color(0x1FB93F38),
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        if (flashMode && actionCount > 0) ...[
          const SizedBox(height: 28),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var index = 0; index < actionCount; index++) ...[
                if (index > 0) SizedBox(width: actionCount > 10 ? 4 : 8),
                AnimatedContainer(
                  duration: Duration(milliseconds: reduceMotion ? 0 : 220),
                  width:
                      (220 / actionCount).clamp(8.0, 20.0) +
                      (index == actionIndex ? 4 : 0),
                  height: index == actionIndex ? 12 : 10,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(99),
                    color: index <= actionIndex
                        ? _TopicChainFlashTrainerState._objectColor
                        : const Color(0x1F7759D6),
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class _LightWaveBurstPainter extends CustomPainter {
  const _LightWaveBurstPainter(this.progress);

  static const _angles = <double>[-160, -128, -52, -20, 20, 52, 128, 160];

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final shortest = size.shortestSide;
    final opacity = (math.sin(progress * math.pi) * 0.22).clamp(0.0, 1.0);
    final startRadius = shortest * (0.27 + progress * 0.16);
    final segmentLength = shortest * 0.17 * math.sin(progress * math.pi);

    for (var index = 0; index < _angles.length; index++) {
      final angle = _angles[index] * math.pi / 180;
      final direction = Offset(math.cos(angle), math.sin(angle));
      final start = center + direction * startRadius;
      final end = center + direction * (startRadius + segmentLength);
      final color = index.isEven
          ? const Color(0xFF7759D6)
          : const Color(0xFF5BC4D6);

      canvas.drawLine(
        start,
        end,
        Paint()
          ..color = color.withValues(alpha: opacity)
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 3,
      );
    }
  }

  @override
  bool shouldRepaint(_LightWaveBurstPainter oldDelegate) {
    return progress != oldDelegate.progress;
  }
}

class _RouteEnergyPulse extends StatelessWidget {
  const _RouteEnergyPulse({required this.pulseKey, required this.reduceMotion});

  final int pulseKey;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    if (reduceMotion) {
      return const SizedBox.shrink();
    }
    return TweenAnimationBuilder<double>(
      key: ValueKey('chain-route-pulse-$pulseKey'),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeInOutCubic,
      builder: (context, progress, child) =>
          CustomPaint(painter: _RouteEnergyPulsePainter(progress)),
    );
  }
}

class _RouteEnergyPulsePainter extends CustomPainter {
  const _RouteEnergyPulsePainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final opacity = (math.sin(progress * math.pi) * 0.82).clamp(0.0, 1.0);
    _drawPulse(
      canvas,
      Offset(size.width * 0.057, size.height * (0.78 - progress * 0.6)),
      const Color(0xFFE45B4E),
      opacity,
    );
    _drawPulse(
      canvas,
      Offset(size.width * 0.941, size.height * (0.22 + progress * 0.56)),
      const Color(0xFF5BC4D6),
      opacity,
    );
  }

  void _drawPulse(Canvas canvas, Offset center, Color color, double opacity) {
    canvas.drawCircle(
      center,
      17,
      Paint()
        ..color = color.withValues(alpha: opacity * 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawCircle(
      center,
      5,
      Paint()..color = color.withValues(alpha: opacity),
    );
  }

  @override
  bool shouldRepaint(_RouteEnergyPulsePainter oldDelegate) {
    return progress != oldDelegate.progress;
  }
}
