import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/flash_cards/flash_cards_audio.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/flash_cards/flash_cards_model.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/topic_chain_flash/check_answer.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_widget.dart';
import 'package:larnes_mobile/trainers/shared/instruction/load_trainer_instruction_duration.dart';
import 'package:larnes_mobile/trainers/shared/instruction/trainer_instruction_scene.dart';
import 'package:larnes_mobile/trainers/shared/instruction/trainer_instruction_typewriter.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';

enum FlashCardsPhase { instruction, countdown, play, reveal }

/// Web v2: `platform/src/trainers/mental-arithmetic/flash-cards/component.tsx`
class FlashCardsTrainer extends StatefulWidget {
  const FlashCardsTrainer({
    super.key,
    required this.params,
    this.onComplete,
  });

  final Map<String, dynamic> params;
  final VoidCallback? onComplete;

  @override
  State<FlashCardsTrainer> createState() => _FlashCardsTrainerState();
}

class _FlashCardsTrainerState extends State<FlashCardsTrainer>
    with SingleTickerProviderStateMixin {
  static const _instructionText = 'Посмотри на абакус и введи число';
  static const _countdownLabels = ['3', '2', '1', 'СТАРТ'];
  static const _countdownStepMs = 750;
  static const _countdownColor = Color(0xFFDC2626);
  static const _wrongFeedbackMs = 450;
  static const _revealDelayMs = 1400;
  static const _successDelayMs = 700;
  static const _completeDelayMs = 700;
  static const _wrongColor = Color(0xFFDC2626);
  static const _okColor = Color(0xFF2B59C3);
  static const _okSoft = Color(0xFFDCE8FF);
  static const _revealSoft = Color(0xFFFEF3C7);
  static const _lineColor = Color(0xFFD5CFC4);

  late final int _totalRods;
  late final List<int> _cardValues;

  var _cardIndex = 0;
  FlashCardsPhase _phase = FlashCardsPhase.instruction;
  String _countdownLabel = _countdownLabels.first;
  var _instructionLength = 0;
  var _failedAttempts = 0;
  var _isWrong = false;
  var _isCorrect = false;
  var _isSubmitting = false;
  var _completeCalled = false;
  Object _runToken = Object();

  final _instructionTypewriter = TrainerInstructionTypewriter();
  final _inputController = TextEditingController();
  final _inputFocus = FocusNode();
  Timer? _countdownTimer;
  Timer? _wrongTimer;
  Timer? _advanceTimer;
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  int get _currentValue =>
      _cardValues.isEmpty ? 0 : _cardValues[_cardIndex.clamp(0, _cardValues.length - 1)];

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
    ]).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
    );
    _startSession();
  }

  @override
  void didUpdateWidget(FlashCardsTrainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.params != widget.params) {
      _startSession();
    }
  }

  @override
  void dispose() {
    _instructionTypewriter.cancel();
    _countdownTimer?.cancel();
    _wrongTimer?.cancel();
    _advanceTimer?.cancel();
    _shakeController.dispose();
    _inputController.dispose();
    _inputFocus.dispose();
    unawaited(cancelFlashCardsAudio());
    super.dispose();
  }

  void _startSession() {
    final runToken = Object();
    _runToken = runToken;
    _instructionTypewriter.cancel();
    _countdownTimer?.cancel();
    _wrongTimer?.cancel();
    _advanceTimer?.cancel();
    unawaited(cancelFlashCardsAudio());
    _inputController.clear();

    _totalRods = widget.params['totalRods'] as int? ?? 1;
    final valuesRaw = widget.params['values'];
    _cardValues = valuesRaw is String
        ? parseFlashCardValues(valuesRaw)
        : const [3, 7, 15];
    _cardIndex = 0;
    _failedAttempts = 0;

    setState(() {
      _phase = FlashCardsPhase.instruction;
      _instructionLength = 0;
      _countdownLabel = _countdownLabels.first;
      _isWrong = false;
      _isCorrect = false;
      _isSubmitting = false;
      _completeCalled = false;
    });

    unawaited(_runInstruction(runToken));
  }

  Future<void> _runInstruction(Object runToken) async {
    final durationMs = await loadTrainerInstructionDurationMs(
      assetPath: getFlashCardsInstructionAudioAsset(),
      playbackRate: kFlashCardsInstructionPlaybackRate,
      fallbackMs: kFlashCardsInstructionDurationFallbackMs,
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

    await playFlashCardsInstruction();
    if (!mounted || !identical(runToken, _runToken)) {
      return;
    }

    _instructionTypewriter.cancel();
    setState(() {
      _instructionLength = _instructionText.length;
      _phase = FlashCardsPhase.countdown;
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
        setState(() {
          _phase = FlashCardsPhase.play;
          _failedAttempts = 0;
          _isWrong = false;
          _isCorrect = false;
          _isSubmitting = false;
        });
        _inputController.clear();
        _focusAnswerInput();
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

  void _focusAnswerInput() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _phase != FlashCardsPhase.play || _isSubmitting) {
        return;
      }
      _inputFocus.requestFocus();
    });
  }

  void _advanceToNextCard() {
    if (_cardIndex + 1 < _cardValues.length) {
      setState(() {
        _cardIndex += 1;
        _phase = FlashCardsPhase.countdown;
        _countdownLabel = _countdownLabels.first;
      });
      _runCountdown(_runToken);
      return;
    }

    if (_completeCalled) {
      return;
    }
    _completeCalled = true;
    _advanceTimer?.cancel();
    _advanceTimer = Timer(const Duration(milliseconds: _completeDelayMs), () {
      if (!mounted) {
        return;
      }
      widget.onComplete?.call();
    });
  }

  void _enterReveal() {
    setState(() {
      _phase = FlashCardsPhase.reveal;
      _isSubmitting = true;
      _isWrong = false;
      _isCorrect = false;
    });
    _inputController.text = '$_currentValue';
    _advanceTimer?.cancel();
    _advanceTimer = Timer(const Duration(milliseconds: _revealDelayMs), () {
      if (!mounted) {
        return;
      }
      _advanceToNextCard();
    });
  }

  void _submit() {
    if (_phase != FlashCardsPhase.play || _isSubmitting) {
      return;
    }

    if (!isCorrectAnswer(_inputController.text, _currentValue)) {
      final nextAttempts = _failedAttempts + 1;
      setState(() {
        _failedAttempts = nextAttempts;
        _isWrong = true;
        _isCorrect = false;
      });
      _shakeController.forward(from: 0);
      _wrongTimer?.cancel();
      _wrongTimer = Timer(const Duration(milliseconds: _wrongFeedbackMs), () {
        if (!mounted) {
          return;
        }

        if (nextAttempts >= 2) {
          _enterReveal();
          return;
        }

        setState(() => _isWrong = false);
        _inputController.clear();
        _focusAnswerInput();
      });
      return;
    }

    setState(() {
      _isWrong = false;
      _isCorrect = true;
      _isSubmitting = true;
    });
    _advanceTimer?.cancel();
    _advanceTimer = Timer(const Duration(milliseconds: _successDelayMs), () {
      if (!mounted) {
        return;
      }
      _advanceToNextCard();
    });
  }

  Color _fieldBorderColor({bool focused = false}) {
    if (_isWrong) {
      return _wrongColor;
    }
    if (_isCorrect || _phase == FlashCardsPhase.reveal) {
      return _okColor;
    }
    if (focused) {
      return _okColor;
    }
    return _lineColor;
  }

  Color _fieldFillColor() {
    if (_isCorrect) {
      return _okSoft;
    }
    if (_phase == FlashCardsPhase.reveal) {
      return _revealSoft;
    }
    return const Color(0xFFFFFCF8);
  }

  Widget _buildCountdown() {
    return Center(
      child: Text(
        _countdownLabel,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: MediaQuery.sizeOf(context).shortestSide * 0.26,
          height: 1,
          color: _countdownColor,
        ),
      ),
    );
  }

  Widget _buildPlayBody() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxHeight = constraints.maxHeight * 0.52;
        final maxWidth = constraints.maxWidth * 0.96;

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: maxHeight,
                    maxWidth: maxWidth,
                  ),
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: AnimatedAbacusValue(
                      value: _currentValue,
                      totalRods: _totalRods,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            AnimatedBuilder(
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
                      enabled: !_isSubmitting && _phase == FlashCardsPhase.play,
                      readOnly: _phase == FlashCardsPhase.reveal,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      autofocus: _phase == FlashCardsPhase.play,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: MediaQuery.sizeOf(context).shortestSide * 0.14,
                        height: 1,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: _isWrong ? _wrongColor : _okColor,
                      ),
                      cursorColor: _isWrong ? _wrongColor : _okColor,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: _fieldFillColor(),
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
                      onChanged: (_) {
                        if (_isWrong) {
                          setState(() => _isWrong = false);
                        }
                      },
                      onSubmitted: (_) => _submit(),
                    ),
                    if (_phase == FlashCardsPhase.play) ...[
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: _isSubmitting || _inputController.text.trim().isEmpty
                            ? null
                            : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: _okColor,
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
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return TrainerScene(
      child: switch (_phase) {
        FlashCardsPhase.instruction => TrainerInstructionScene(
          length: _instructionLength,
          text: _instructionText,
        ),
        FlashCardsPhase.countdown => _buildCountdown(),
        FlashCardsPhase.play || FlashCardsPhase.reveal => _buildPlayBody(),
      },
    );
  }
}
