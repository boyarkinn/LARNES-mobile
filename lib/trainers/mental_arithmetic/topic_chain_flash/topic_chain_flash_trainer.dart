import 'dart:async';

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/audio/flash_audio_tempo.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/audio/play_step_audio.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/generate.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/types.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/topic_chain_flash/answer_fireworks.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/topic_chain_flash/check_answer.dart';
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

enum _Phase { boot, countdown, flash, answer, error }

class _TopicChainFlashTrainerState extends State<TopicChainFlashTrainer>
    with SingleTickerProviderStateMixin {
  static const _wrongFeedbackMs = 450;
  /// Пауза после верного ответа — успеть увидеть фейерверки (мок A).
  static const _successFeedbackMs = 900;
  static const _wrongColor = Color(0xFFDC2626);
  static const _okSoft = Color(0xFFDCE8FF);

  /// Пауза между вспышками — иначе подряд одинаковые шаги (+1 +1) сливаются в одно.
  static const _interFlashBlankMs = 120;

  /// Обратный отсчёт перед каждым примером — ребёнок успевает взять абакус.
  static const _countdownStepMs = 750;
  static const _countdownLabels = ['3', '2', '1', 'СТАРТ'];
  static const _countdownColor = Color(0xFFDC2626);
  static const _flashColor = Color(0xFF2B59C3);

  _Phase _phase = _Phase.boot;
  Chain? _chain;
  var _exampleIndex = 0;
  String? _flashLabel;
  String _answerDraft = '';
  bool _isWrong = false;
  bool _isCorrect = false;
  var _fireworksKey = 0;
  bool _hasFailedAttempt = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  bool _completeCalled = false;
  Object _runToken = Object();
  Timer? _flashTimer;
  Timer? _countdownTimer;
  Timer? _wrongTimer;
  Timer? _completeTimer;
  final _inputController = TextEditingController();
  final _inputFocus = FocusNode();
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  int get _totalExamples =>
      _readIntParam(widget.params['exampleCount'], 1).clamp(1, 10);

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
        a['exampleCount'] != b['exampleCount'];
  }

  void _startSession() {
    _completeCalled = false;
    _startExample(0, resetCompleteFlag: true);
  }

  void _startExample(int nextIndex, {bool resetCompleteFlag = false}) {
    _flashTimer?.cancel();
    _countdownTimer?.cancel();
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
    _hasFailedAttempt = false;
    _isSubmitting = false;
    _flashLabel = null;
    _errorMessage = null;
    _exampleIndex = nextIndex;

    final runToken = Object();
    _runToken = runToken;

    try {
      final chain = generateChain(
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
        _phase = _Phase.answer;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && identical(runToken, _runToken)) {
          _inputFocus.requestFocus();
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
      setState(() => _flashLabel = formatChainStep(step));
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
          _inputController.clear();
        });
        _inputFocus.requestFocus();
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
    _completeTimer = Timer(const Duration(milliseconds: _successFeedbackMs), () {
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
    });
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
                    ? const Color(0xFF262626)
                    : const Color(0xFFD6D3D1),
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
              _Phase.countdown ||
              _Phase.flash => AnimatedOpacity(
                opacity: _flashLabel == null ? 0 : 1,
                duration: const Duration(milliseconds: 150),
                child: Text(
                  _flashLabel ?? ' ',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: MediaQuery.sizeOf(context).shortestSide * 0.26,
                    height: 1,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: _phase == _Phase.countdown
                        ? _countdownColor
                        : _flashColor,
                  ),
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
                                MediaQuery.sizeOf(context).shortestSide * 0.14,
                            height: 1,
                            fontFeatures: const [FontFeature.tabularFigures()],
                            color: _isWrong ? _wrongColor : _flashColor,
                          ),
                          cursorColor: _isWrong ? _wrongColor : _flashColor,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: _isCorrect
                                ? _okSoft
                                : const Color(0xFFFFFCF8),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide(
                                width: 1.5,
                                color: _fieldBorderColor(),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide(
                                width: 1.5,
                                color: _fieldBorderColor(),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide(
                                width: 1.5,
                                color: _fieldBorderColor(focused: true),
                              ),
                            ),
                            disabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide(
                                width: 1.5,
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
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: _isSubmitting || _answerDraft.trim().isEmpty
                            ? null
                            : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: _flashColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Проверить'),
                      ),
                      if (_hasFailedAttempt) ...[
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: _isSubmitting ? null : _replayExample,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF1A1D2E),
                            side: const BorderSide(
                              width: 1.5,
                              color: Color(0xFFD5CFC4),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Повторить'),
                        ),
                      ],
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
