import 'dart:async';

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/math/fruit_count_tap/fruit_reveal.dart';
import 'package:larnes_mobile/trainers/math/number_composition/composition_dot_group.dart';
import 'package:larnes_mobile/trainers/math/number_composition/composition_sizes.dart';
import 'package:larnes_mobile/trainers/math/number_composition/number_composition_model.dart';

/// Web v2: `platform/src/trainers/math/number-composition/dot-choice-bar.tsx`
class DotChoiceBar extends StatelessWidget {
  const DotChoiceBar({
    super.key,
    required this.disabled,
    required this.onSelect,
    this.selectedValue,
    this.wrongValue,
    this.dotChoiceSize = 80,
    this.buttonHeight = 72,
  });

  final bool disabled;
  final ValueChanged<int> onSelect;
  final int? selectedValue;
  final int? wrongValue;
  final double dotChoiceSize;
  final double buttonHeight;

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
              isPlaced:
                  selectedValue == dotAnswerChoices[index] && wrongValue == null,
              enterDelayMs: getAnswerRevealDelayMs(index, dotAnswerChoices.length),
              dotChoiceSize: dotChoiceSize,
              buttonHeight: buttonHeight,
              onSelect: onSelect,
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
    required this.isPlaced,
    required this.enterDelayMs,
    required this.dotChoiceSize,
    required this.buttonHeight,
    required this.onSelect,
  });

  final int value;
  final bool disabled;
  final bool isCorrect;
  final bool isWrong;
  final bool isPlaced;
  final int enterDelayMs;
  final double dotChoiceSize;
  final double buttonHeight;
  final ValueChanged<int> onSelect;

  @override
  State<_DotChoiceButton> createState() => _DotChoiceButtonState();
}

class _DotChoiceButtonState extends State<_DotChoiceButton>
    with TickerProviderStateMixin {
  late final AnimationController _shakeController;
  late final Animation<double> _shakeOffset;
  AnimationController? _enterController;
  Animation<double>? _enterProgress;
  Timer? _enterTimer;

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
    _scheduleEnterAnimation();
  }

  void _scheduleEnterAnimation() {
    _enterController?.dispose();
    _enterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: kFruitPopDurationMs),
    );
    _enterProgress = CurvedAnimation(
      parent: _enterController!,
      curve: Curves.easeOutBack,
    );

    if (widget.enterDelayMs <= 0) {
      _enterController!.value = 1;
      return;
    }

    _enterTimer = Timer(Duration(milliseconds: widget.enterDelayMs), () {
      if (mounted) {
        _enterController!.forward();
      }
    });
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
    _enterTimer?.cancel();
    _shakeController.dispose();
    _enterController?.dispose();
    super.dispose();
  }

  Color get _borderColor {
    if (widget.isWrong) {
      return const Color(0xFFFCA5A5);
    }
    return const Color(0xFFE5E7EB);
  }

  Widget _buildChip({double opacity = 1}) {
    return Opacity(
      opacity: opacity,
      child: Material(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        elevation: 0,
        child: Container(
          height: widget.buttonHeight,
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
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: CompositionDotGroup(
                count: widget.value,
                frameSize: widget.dotChoiceSize,
                variant: CompositionDotVariant.choice,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isPlaced) {
      return Opacity(opacity: 0, child: _buildChip());
    }

    final enterProgress = _enterProgress;

    Widget button = AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeOffset.value, 0),
          child: child,
        );
      },
      child: Draggable<int>(
        data: widget.value,
        maxSimultaneousDrags: widget.disabled ? 0 : 1,
        feedback: Material(
          color: Colors.transparent,
          child: _buildChip(opacity: 0.95),
        ),
        childWhenDragging: Opacity(
          opacity: 0.35,
          child: _buildChip(),
        ),
        child: InkWell(
          onTap: widget.disabled ? null : () => widget.onSelect(widget.value),
          borderRadius: BorderRadius.circular(16),
          child: _buildChip(),
        ),
      ),
    );

    if (enterProgress != null) {
      button = AnimatedBuilder(
        animation: enterProgress,
        builder: (context, child) {
          final t = enterProgress.value.clamp(0.0, 1.0);
          return Opacity(
            opacity: t,
            child: Transform.scale(
              scale: 0.88 + 0.12 * t,
              child: child,
            ),
          );
        },
        child: button,
      );
    }

    return button;
  }
}
