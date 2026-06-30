import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/math/number_composition/number_composition_model.dart';
import 'package:larnes_mobile/trainers/shared/dot_group.dart';

class DotChoiceBar extends StatelessWidget {
  const DotChoiceBar({
    super.key,
    required this.disabled,
    required this.onSelect,
    this.selectedValue,
    this.wrongValue,
  });

  final bool disabled;
  final ValueChanged<int> onSelect;
  final int? selectedValue;
  final int? wrongValue;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var index = 0; index < dotAnswerChoices.length; index++) ...[
          if (index > 0) const SizedBox(width: 8),
          Expanded(
            child: _DotChoiceButton(
              value: dotAnswerChoices[index],
              disabled: disabled,
              isCorrect:
                  selectedValue == dotAnswerChoices[index] && wrongValue == null,
              isWrong: wrongValue == dotAnswerChoices[index],
              onTap: () => onSelect(dotAnswerChoices[index]),
            ),
          ),
        ],
      ],
    );
  }
}

class _DotChoiceButton extends StatefulWidget {
  const _DotChoiceButton({
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
  State<_DotChoiceButton> createState() => _DotChoiceButtonState();
}

class _DotChoiceButtonState extends State<_DotChoiceButton>
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
  void didUpdateWidget(_DotChoiceButton oldWidget) {
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

  Color get _borderColor {
    if (widget.isWrong) {
      return const Color(0xFFFCA5A5);
    }
    if (widget.isCorrect) {
      return const Color(0xFF4ADE80);
    }
    return const Color(0xFFE5E7EB);
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
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _borderColor),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0D000000),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Center(
                child: DotGroup(
                  count: widget.value,
                  size: DotGroupSize.sm,
                  tone: DotGroupTone.indigo,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
