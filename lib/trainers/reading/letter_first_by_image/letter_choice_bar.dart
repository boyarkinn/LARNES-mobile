import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:larnes_mobile/trainers/math/fruit_count_tap/fruit_reveal.dart';

const _popCurve = Cubic(0.34, 1.2, 0.64, 1);
const _foundGreen = Color(0xFF16A34A);
const _wrongRed = Color(0xFFDC2626);
const _fallbackLetterColor = Color(0xFF1F2937);

/// Web: `platform/src/trainers/reading/letter-first-by-image/letter-choice-bar.tsx`
class LetterChoiceBar extends StatelessWidget {
  const LetterChoiceBar({
    super.key,
    required this.choices,
    required this.choiceColors,
    required this.disabled,
    required this.isRevealComplete,
    required this.onSelect,
    required this.selectedLetter,
    required this.wrongLetter,
    required this.buttonHeight,
    required this.fontSize,
    required this.viewportWidth,
    this.gap = 8,
  });

  final List<String> choices;
  final Map<String, Color> choiceColors;
  final bool disabled;
  final bool isRevealComplete;
  final ValueChanged<String> onSelect;
  final String? selectedLetter;
  final String? wrongLetter;
  final double buttonHeight;
  final double fontSize;
  final double viewportWidth;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final choiceCount = choices.length;
    final crossAxisCount = getLetterChoiceCrossAxisCount(
      choiceCount,
      viewportWidth,
    );

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: gap,
        crossAxisSpacing: gap,
        mainAxisExtent: buttonHeight,
      ),
      itemCount: choiceCount,
      itemBuilder: (context, index) {
        final letter = choices[index];
        final displayColor = choiceColors[letter] ?? _fallbackLetterColor;
        final isCorrect = selectedLetter == letter && wrongLetter == null;
        final isWrong = wrongLetter == letter;

        return _LetterChoiceButton(
          key: ValueKey('$letter-$index'),
          letter: letter,
          displayColor: displayColor,
          disabled: disabled || !isRevealComplete,
          isCorrect: isCorrect,
          isWrong: isWrong,
          enterDelayMs: getAnswerRevealDelayMs(index, choiceCount),
          buttonHeight: buttonHeight,
          fontSize: fontSize,
          onTap: () => onSelect(letter),
        );
      },
    );
  }
}

int getLetterChoiceCrossAxisCount(int choiceCount, double viewportWidth) {
  if (choiceCount <= 4) {
    return 4;
  }

  if (choiceCount <= 6) {
    return viewportWidth >= 640 ? 6 : 3;
  }

  return 4;
}

class _LetterChoiceButton extends StatefulWidget {
  const _LetterChoiceButton({
    super.key,
    required this.letter,
    required this.displayColor,
    required this.disabled,
    required this.isCorrect,
    required this.isWrong,
    required this.enterDelayMs,
    required this.buttonHeight,
    required this.fontSize,
    required this.onTap,
  });

  final String letter;
  final Color displayColor;
  final bool disabled;
  final bool isCorrect;
  final bool isWrong;
  final int enterDelayMs;
  final double buttonHeight;
  final double fontSize;
  final VoidCallback onTap;

  @override
  State<_LetterChoiceButton> createState() => _LetterChoiceButtonState();
}

class _LetterChoiceButtonState extends State<_LetterChoiceButton>
    with TickerProviderStateMixin {
  late final AnimationController _enterController;
  late final Animation<double> _enterProgress;
  late final AnimationController _shakeController;
  late final Animation<double> _shakeOffset;
  late final AnimationController _foundController;
  late final Animation<double> _foundScale;
  Timer? _enterTimer;

  @override
  void initState() {
    super.initState();
    _enterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: kFruitPopDurationMs),
    );
    _enterProgress = CurvedAnimation(parent: _enterController, curve: _popCurve);

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _shakeOffset = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -6.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -6.0, end: 6.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 6.0, end: -4.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -4.0, end: 4.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 4.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut));

    _foundController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _foundScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.1), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.1, end: 1.0), weight: 1),
    ]).animate(_foundController);

    _scheduleEnterAnimation();

    if (widget.isWrong) {
      _shakeController.forward(from: 0);
    }
    if (widget.isCorrect) {
      _foundController.forward(from: 0);
    }
  }

  void _scheduleEnterAnimation() {
    if (widget.enterDelayMs <= 0) {
      _enterController.value = 1;
      return;
    }

    _enterTimer = Timer(Duration(milliseconds: widget.enterDelayMs), () {
      if (mounted) {
        _enterController.forward();
      }
    });
  }

  @override
  void didUpdateWidget(_LetterChoiceButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isWrong && widget.isWrong) {
      _shakeController.forward(from: 0);
    }
    if (!oldWidget.isCorrect && widget.isCorrect) {
      _foundController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _enterTimer?.cancel();
    _enterController.dispose();
    _shakeController.dispose();
    _foundController.dispose();
    super.dispose();
  }

  Color get _textColor {
    if (widget.isWrong) {
      return _wrongRed;
    }
    if (widget.isCorrect) {
      return _foundGreen;
    }
    return widget.displayColor;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _enterProgress,
        _shakeController,
        _foundController,
      ]),
      builder: (context, child) {
        final enterT = _enterProgress.value.clamp(0.0, 1.0);
        final scale = widget.isCorrect
            ? _foundScale.value.clamp(0.88, 1.1)
            : 0.88 + 0.12 * enterT;

        return Opacity(
          opacity: enterT,
          child: Transform.translate(
            offset: Offset(_shakeOffset.value, 0),
            child: Transform.scale(
              scale: scale,
              child: child,
            ),
          ),
        );
      },
      child: Material(
        color: Colors.white.withValues(alpha: 0.7),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xCCE5E7EB)),
        ),
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        child: InkWell(
          onTap: widget.disabled ? null : widget.onTap,
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: widget.buttonHeight,
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  widget.letter,
                  style: GoogleFonts.onest(
                    fontSize: widget.fontSize,
                    fontWeight: FontWeight.w700,
                    color: _textColor,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
