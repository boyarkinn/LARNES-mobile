import 'dart:async';

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/math/digit_find_tap/digit_colors.dart';
import 'package:larnes_mobile/trainers/math/fruit_count_tap/fruit_reveal.dart';
import 'package:larnes_mobile/trainers/math/number_composition/composition_sizes.dart';

/// Web v2: `platform/src/trainers/math/number-composition/digit-choice-bar.tsx`
class DigitChoiceBar extends StatelessWidget {
  const DigitChoiceBar({
    super.key,
    required this.choices,
    required this.disabled,
    required this.onSelect,
    this.selectedValue,
    this.wrongValue,
    this.buttonHeight = 72,
    this.fontSize = 48,
  });

  final List<int> choices;
  final bool disabled;
  final ValueChanged<int> onSelect;
  final int? selectedValue;
  final int? wrongValue;
  final double buttonHeight;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var index = 0; index < choices.length; index++) ...[
          if (index > 0) const SizedBox(width: 8),
          Expanded(
            child: _DigitChoiceButton(
              value: choices[index],
              disabled: disabled,
              isWrong: wrongValue == choices[index],
              isPlaced:
                  selectedValue == choices[index] && wrongValue == null,
              enterDelayMs: getAnswerRevealDelayMs(index, choices.length),
              buttonHeight: buttonHeight,
              fontSize: fontSize,
              onSelect: onSelect,
            ),
          ),
        ],
      ],
    );
  }
}

class _DigitChoiceButton extends StatefulWidget {
  const _DigitChoiceButton({
    required this.value,
    required this.disabled,
    required this.isWrong,
    required this.isPlaced,
    required this.enterDelayMs,
    required this.buttonHeight,
    required this.fontSize,
    required this.onSelect,
  });

  final int value;
  final bool disabled;
  final bool isWrong;
  final bool isPlaced;
  final int enterDelayMs;
  final double buttonHeight;
  final double fontSize;
  final ValueChanged<int> onSelect;

  @override
  State<_DigitChoiceButton> createState() => _DigitChoiceButtonState();
}

class _DigitChoiceButtonState extends State<_DigitChoiceButton>
    with TickerProviderStateMixin {
  late final AnimationController _shakeController;
  late final Animation<double> _shakeOffset;
  AnimationController? _enterController;
  Animation<double>? _enterProgress;
  Timer? _enterTimer;

  Color get _baseColor => getDigitDisplayColor(widget.value);

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
  void didUpdateWidget(_DigitChoiceButton oldWidget) {
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

  Color get _textColor {
    if (widget.isWrong) {
      return const Color(0xFFDC2626);
    }
    return _baseColor;
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
            border: Border.all(
              color: widget.isWrong
                  ? const Color(0xFFFCA5A5)
                  : const Color(0xFFE5E7EB),
            ),
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
              child: Text(
                '${widget.value}',
                style: TextStyle(
                  fontSize: widget.fontSize,
                  fontWeight: FontWeight.w700,
                  color: _textColor,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
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
