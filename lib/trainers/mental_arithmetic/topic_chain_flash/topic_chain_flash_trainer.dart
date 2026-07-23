import 'dart:async';
import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/generate.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/types.dart';
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

enum _Phase { boot, flash, answer, error }

class _TopicChainFlashTrainerState extends State<TopicChainFlashTrainer>
    with SingleTickerProviderStateMixin {
  static const _wrongFeedbackMs = 450;
  static const _completeDelayMs = 500;

  _Phase _phase = _Phase.boot;
  Chain? _chain;
  String? _flashLabel;
  String _answerDraft = '';
  bool _isWrong = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  bool _completeCalled = false;
  Object _runToken = Object();
  Timer? _flashTimer;
  Timer? _wrongTimer;
  Timer? _completeTimer;
  final _inputController = TextEditingController();
  final _inputFocus = FocusNode();
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _wrongFeedbackMs),
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -8), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8, end: 8), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 8, end: -5), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -5, end: 5), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 5, end: 0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut));
    _startRound();
  }

  @override
  void didUpdateWidget(TopicChainFlashTrainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_semanticParamsChanged(oldWidget.params, widget.params)) {
      _startRound();
    }
  }

  @override
  void dispose() {
    _flashTimer?.cancel();
    _wrongTimer?.cancel();
    _completeTimer?.cancel();
    _shakeController.dispose();
    _inputController.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  bool _semanticParamsChanged(
    Map<String, dynamic> a,
    Map<String, dynamic> b,
  ) {
    return a['topicId'] != b['topicId'] ||
        a['actionCount'] != b['actionCount'] ||
        a['signMode'] != b['signMode'] ||
        a['amountScope'] != b['amountScope'];
  }

  void _startRound() {
    _flashTimer?.cancel();
    _wrongTimer?.cancel();
    _completeTimer?.cancel();
    _completeCalled = false;
    _inputController.clear();
    _answerDraft = '';
    _isWrong = false;
    _isSubmitting = false;
    _flashLabel = null;
    _errorMessage = null;

    final runToken = Object();
    _runToken = runToken;

    try {
      final chain = generateChain(
        GenerateConfig(
          topicId: widget.params['topicId'] as String? ?? 'simple-1',
          actionCount: widget.params['actionCount'] as int? ?? 5,
          signMode: widget.params['signMode'] as String? ?? 'mix',
          amountScope: widget.params['amountScope'] as String? ?? 'topic',
        ),
      );

      if (!mounted || !identical(runToken, _runToken)) {
        return;
      }

      setState(() {
        _chain = chain;
        _phase = _Phase.flash;
      });
      _runFlash(runToken, chain);
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
        _errorMessage = 'Не удалось собрать цепочку. Попробуйте другие параметры.';
      });
    } catch (_) {
      setState(() {
        _chain = null;
        _phase = _Phase.error;
        _errorMessage = 'Ошибка генерации.';
      });
    }
  }

  void _runFlash(Object runToken, Chain chain) {
    final stepPauseSec =
        (widget.params['stepPauseSec'] as num?)?.toDouble() ?? 1;
    final pause = Duration(milliseconds: (stepPauseSec * 1000).round());
    var index = 0;

    void showNext() {
      if (!mounted || !identical(runToken, _runToken)) {
        return;
      }

      if (index >= chain.steps.length) {
        setState(() {
          _flashLabel = null;
          _phase = _Phase.answer;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && identical(runToken, _runToken)) {
            _inputFocus.requestFocus();
          }
        });
        return;
      }

      final step = chain.steps[index];
      setState(() => _flashLabel = formatChainStep(step));
      index += 1;
      _flashTimer = Timer(pause, showNext);
    }

    showNext();
  }

  void _submit() {
    final chain = _chain;
    if (chain == null || _isSubmitting || _phase != _Phase.answer) {
      return;
    }

    if (!isCorrectAnswer(_answerDraft, chain.answer)) {
      setState(() => _isWrong = true);
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

    setState(() => _isSubmitting = true);
    _completeTimer?.cancel();
    _completeTimer = Timer(const Duration(milliseconds: _completeDelayMs), () {
      if (_completeCalled || !mounted) {
        return;
      }
      _completeCalled = true;
      widget.onComplete?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    return TrainerScene(
      child: Center(
        child: switch (_phase) {
          _Phase.error => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _errorMessage ?? 'Ошибка',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Color(0xFF57534E)),
              ),
            ),
          _Phase.boot || _Phase.flash => AnimatedOpacity(
              opacity: _flashLabel == null ? 0 : 1,
              duration: const Duration(milliseconds: 150),
              child: Text(
                _flashLabel ?? ' ',
                style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: MediaQuery.sizeOf(context).shortestSide * 0.22,
                  height: 1,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: const Color(0xFF262626),
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
                    TextField(
                      controller: _inputController,
                      focusNode: _inputFocus,
                      enabled: !_isSubmitting,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      autofocus: true,
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: MediaQuery.sizeOf(context).shortestSide * 0.12,
                        height: 1,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: const Color(0xFF171717),
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xCCFFFFFF),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            width: 2,
                            color: _isWrong
                                ? const Color(0xFFEF4444)
                                : const Color(0xFFD6D3D1),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            width: 2,
                            color: _isWrong
                                ? const Color(0xFFEF4444)
                                : const Color(0xFFD6D3D1),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            width: 2,
                            color: _isWrong
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF262626),
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
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _isSubmitting || _answerDraft.trim().isEmpty
                          ? null
                          : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF171717),
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
                  ],
                ),
              ),
            ),
        },
      ),
    );
  }
}
