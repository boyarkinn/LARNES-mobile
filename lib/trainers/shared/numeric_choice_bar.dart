import 'package:flutter/material.dart';

/// Четыре (или N) числовых кнопок ответа — порт web `AnswerBar` / `DigitChoiceBar`.
class NumericChoiceBar extends StatelessWidget {
  const NumericChoiceBar({
    super.key,
    required this.choices,
    required this.disabled,
    required this.onSelect,
    this.selectedValue,
    this.wrongValue,
  });

  final List<int> choices;
  final bool disabled;
  final ValueChanged<int> onSelect;
  final int? selectedValue;
  final int? wrongValue;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var index = 0; index < choices.length; index++) ...[
          if (index > 0) const SizedBox(width: 8),
          Expanded(
            child: _NumericChoiceButton(
              value: choices[index],
              disabled: disabled,
              isCorrect: selectedValue == choices[index] && wrongValue == null,
              isWrong: wrongValue == choices[index],
              onTap: () => onSelect(choices[index]),
            ),
          ),
        ],
      ],
    );
  }
}

class _NumericChoiceButton extends StatefulWidget {
  const _NumericChoiceButton({
    required this.value,
    required this.disabled,
    required this.isCorrect,
    required this.isWrong,
    required this.onTap,
  });

  final int value;
  final bool disabled;
  final bool isCorrect;
  final bool isWrong;
  final VoidCallback onTap;

  @override
  State<_NumericChoiceButton> createState() => _NumericChoiceButtonState();
}

class _NumericChoiceButtonState extends State<_NumericChoiceButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shakeController;
  late final Animation<double> _shakeOffset;

  @override
  void initState() {
    super.initState();
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

    if (widget.isWrong) {
      _shakeController.forward(from: 0);
    }
  }

  @override
  void didUpdateWidget(_NumericChoiceButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isWrong && widget.isWrong) {
      _shakeController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  Color get _textColor {
    if (widget.isWrong) {
      return const Color(0xFFDC2626);
    }
    if (widget.isCorrect) {
      return const Color(0xFF16A34A);
    }
    return const Color(0xFF1F2937);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeOffset.value, 0),
          child: child,
        );
      },
      child: AnimatedScale(
        scale: widget.isCorrect ? 1.06 : 1.0,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutBack,
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          elevation: 0,
          child: InkWell(
            onTap: widget.disabled ? null : widget.onTap,
            borderRadius: BorderRadius.circular(16),
            child: Ink(
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0D000000),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '${widget.value}',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: _textColor,
                    fontFeatures: const [FontFeature.tabularFigures()],
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
