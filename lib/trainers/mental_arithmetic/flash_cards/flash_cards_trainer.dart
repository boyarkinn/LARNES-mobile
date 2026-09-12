import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/flash_cards/flash_cards_audio.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/flash_cards/flash_cards_model.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_widget.dart';
import 'package:larnes_mobile/trainers/shared/instruction/load_trainer_instruction_duration.dart';
import 'package:larnes_mobile/trainers/shared/instruction/trainer_instruction_scene.dart';
import 'package:larnes_mobile/trainers/shared/instruction/trainer_instruction_typewriter.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';

enum FlashCardsPhase { instruction, countdown, play, reveal }

/// Web v2: `platform/src/trainers/mental-arithmetic/flash-cards/component.tsx`
class FlashCardsTrainer extends StatefulWidget {
  const FlashCardsTrainer({super.key, required this.params, this.onComplete});

  final Map<String, dynamic> params;
  final VoidCallback? onComplete;

  @override
  State<FlashCardsTrainer> createState() => _FlashCardsTrainerState();
}

class _FlashCardsTrainerState extends State<FlashCardsTrainer>
    with SingleTickerProviderStateMixin {
  static const _instructionText = kFlashCardsInstructionText;
  static const _countdownLabels = ['3', '2', '1', 'СТАРТ'];
  static const _countdownStepMs = 750;
  static const _countdownColor = Color(0xFFE45B4E);
  static const _wrongFeedbackMs = 450;
  static const _revealDelayMs = 1400;
  static const _successDelayMs = 700;
  static const _completeDelayMs = 700;
  static const _wrongColor = Color(0xFFDC2626);
  static const _objectColor = Color(0xFFE45B4E);
  static const _objectDeep = Color(0xFFB93F38);
  static const _purple = Color(0xFF7759D6);
  static const _successColor = Color(0xFF16A34A);

  late final int _totalRods;
  late final List<int> _cardValues;
  List<int> _answerOptions = const [];

  var _cardIndex = 0;
  FlashCardsPhase _phase = FlashCardsPhase.instruction;
  String _countdownLabel = _countdownLabels.first;
  var _instructionLength = 0;
  var _failedAttempts = 0;
  var _isWrong = false;
  var _isCorrect = false;
  var _isSubmitting = false;
  var _completeCalled = false;
  int? _selectedAnswer;
  final _rejectedAnswers = <int>{};
  Object _runToken = Object();

  final _instructionTypewriter = TrainerInstructionTypewriter();
  Timer? _countdownTimer;
  Timer? _wrongTimer;
  Timer? _advanceTimer;
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  int get _currentValue => _cardValues.isEmpty
      ? 0
      : _cardValues[_cardIndex.clamp(0, _cardValues.length - 1)];

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

    _totalRods = widget.params['totalRods'] as int? ?? 1;
    final valuesRaw = widget.params['values'];
    _cardValues = valuesRaw is String
        ? parseFlashCardValues(valuesRaw)
        : const [3, 7, 15];
    _cardIndex = 0;
    _answerOptions = buildFlashCardAnswerOptions(_currentValue);
    _failedAttempts = 0;
    _selectedAnswer = null;
    _rejectedAnswers.clear();

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
          _selectedAnswer = null;
          _rejectedAnswers.clear();
          _isWrong = false;
          _isCorrect = false;
          _isSubmitting = false;
        });
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

  void _advanceToNextCard() {
    if (_cardIndex + 1 < _cardValues.length) {
      setState(() {
        _cardIndex += 1;
        _answerOptions = buildFlashCardAnswerOptions(_currentValue);
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
    _advanceTimer?.cancel();
    _advanceTimer = Timer(const Duration(milliseconds: _revealDelayMs), () {
      if (!mounted) {
        return;
      }
      _advanceToNextCard();
    });
  }

  void _submit(int answer) {
    if (_phase != FlashCardsPhase.play ||
        _isSubmitting ||
        _rejectedAnswers.contains(answer)) {
      return;
    }

    setState(() => _selectedAnswer = answer);

    if (answer != _currentValue) {
      final nextAttempts = _failedAttempts + 1;
      setState(() {
        _failedAttempts = nextAttempts;
        _isWrong = true;
        _isCorrect = false;
        _isSubmitting = true;
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

        setState(() {
          _rejectedAnswers.add(answer);
          _selectedAnswer = null;
          _isWrong = false;
          _isSubmitting = false;
        });
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

  Widget _buildAnswerButton(int answer, double width) {
    final correctChoice =
        (_isCorrect && _selectedAnswer == answer) ||
        (_phase == FlashCardsPhase.reveal && answer == _currentValue);
    final wrongChoice = _isWrong && _selectedAnswer == answer;
    final rejectedChoice = _rejectedAnswers.contains(answer);
    final disabled =
        _phase == FlashCardsPhase.reveal || _isSubmitting || rejectedChoice;
    final backgroundColor = correctChoice
        ? const Color(0xD1DCFCE7)
        : wrongChoice
        ? const Color(0xD1FEE2E2)
        : const Color(0x73FFFFFF);
    final borderColor = correctChoice
        ? _successColor.withValues(alpha: 0.5)
        : wrongChoice
        ? _wrongColor.withValues(alpha: 0.5)
        : _purple.withValues(alpha: 0.2);
    final foregroundColor = correctChoice
        ? _successColor
        : wrongChoice
        ? _wrongColor
        : rejectedChoice
        ? _purple.withValues(alpha: 0.32)
        : _objectDeep;

    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) => Transform.translate(
        offset: wrongChoice ? Offset(_shakeAnimation.value, 0) : Offset.zero,
        child: child,
      ),
      child: SizedBox(
        width: width,
        height: 76,
        child: OutlinedButton(
          onPressed: disabled ? null : () => _submit(answer),
          style: OutlinedButton.styleFrom(
            backgroundColor: backgroundColor,
            disabledBackgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            disabledForegroundColor: foregroundColor,
            elevation: correctChoice ? 3 : 1,
            shadowColor: correctChoice
                ? _successColor.withValues(alpha: 0.2)
                : _purple.withValues(alpha: 0.12),
            side: BorderSide(color: borderColor),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Center(
                child: Text(
                  '$answer',
                  style: const TextStyle(
                    fontSize: 34,
                    height: 1,
                    fontWeight: FontWeight.w700,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              if (correctChoice)
                const Positioned(
                  right: 0,
                  top: 0,
                  child: Icon(Icons.check_rounded, size: 21),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayBody() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxHeight = constraints.maxHeight * 0.52;
        final maxWidth = constraints.maxWidth * 0.96;
        final answerWidth = math.min(constraints.maxWidth * 0.94, 560.0);
        final optionWidth = (answerWidth - 12) / 2;
        final feedback = _phase == FlashCardsPhase.reveal
            ? 'Правильный ответ: $_currentValue'
            : _isCorrect
            ? 'Верно!'
            : _isWrong
            ? 'Попробуй ещё раз'
            : 'Выбери правильное число';

        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_cardValues.length > 1)
                Semantics(
                  label: 'Карточка ${_cardIndex + 1} из ${_cardValues.length}',
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _cardValues.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: index <= _cardIndex
                              ? _objectColor
                              : _purple.withValues(alpha: 0.14),
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 10),
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
                        activeBeadColor: const Color(
                          kFlashCardsActiveBeadColor,
                        ),
                        value: _currentValue,
                        totalRods: _totalRods,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Semantics(
                container: true,
                liveRegion: true,
                label: feedback,
                child: const SizedBox.shrink(),
              ),
              SizedBox(
                width: answerWidth,
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _answerOptions
                      .map((answer) => _buildAnswerButton(answer, optionWidth))
                      .toList(growable: false),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_phase == FlashCardsPhase.instruction) {
      return TrainerInstructionScene(
        length: _instructionLength,
        text: _instructionText,
      );
    }

    return TrainerScene(
      child: _phase == FlashCardsPhase.countdown
          ? _buildCountdown()
          : _buildPlayBody(),
    );
  }
}
