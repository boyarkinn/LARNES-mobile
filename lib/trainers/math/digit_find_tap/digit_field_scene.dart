import 'dart:async';

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/math/digit_find_tap/digit_chip_size.dart';
import 'package:larnes_mobile/trainers/math/digit_find_tap/digit_colors.dart';
import 'package:larnes_mobile/trainers/math/digit_find_tap/digit_find_tap_layout.dart';
import 'package:larnes_mobile/trainers/math/digit_find_tap/digit_found_burst.dart';
import 'package:larnes_mobile/trainers/math/fruit_count_tap/fruit_reveal.dart';

enum DigitChipState { normal, found, wrong }

/// Web v2: `platform/src/trainers/math/digit-find-tap/digit-field-scene.tsx`
class DigitFieldScene extends StatelessWidget {
  const DigitFieldScene({
    super.key,
    required this.digits,
    required this.disabled,
    required this.foundIds,
    required this.onTap,
    required this.wrongId,
  });

  final List<PlacedDigit> digits;
  final bool disabled;
  final Set<String> foundIds;
  final ValueChanged<String> onTap;
  final String? wrongId;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final chipSize = getDigitChipSizePx(constraints.maxHeight);
        final fontSize = getDigitChipFontSizePx(chipSize);
        final digitCount = digits.length;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            for (var index = 0; index < digits.length; index++)
              Positioned(
                left: digits[index].xPercent / 100 * constraints.maxWidth,
                top: digits[index].yPercent / 100 * constraints.maxHeight,
                child: _DigitChip(
                  key: ValueKey(digits[index].id),
                  digit: digits[index],
                  chipSize: chipSize,
                  fontSize: fontSize,
                  disabled: disabled,
                  enterDelayMs: getFruitRevealDelayMs(index, digitCount),
                  state: foundIds.contains(digits[index].id)
                      ? DigitChipState.found
                      : wrongId == digits[index].id
                          ? DigitChipState.wrong
                          : DigitChipState.normal,
                  onTap: () => onTap(digits[index].id),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _DigitChip extends StatefulWidget {
  const _DigitChip({
    super.key,
    required this.digit,
    required this.chipSize,
    required this.fontSize,
    required this.disabled,
    required this.enterDelayMs,
    required this.state,
    required this.onTap,
  });

  final PlacedDigit digit;
  final double chipSize;
  final double fontSize;
  final bool disabled;
  final int enterDelayMs;
  final DigitChipState state;
  final VoidCallback onTap;

  @override
  State<_DigitChip> createState() => _DigitChipState();
}

class _DigitChipState extends State<_DigitChip> with TickerProviderStateMixin {
  late final AnimationController _shakeController;
  late final Animation<double> _shakeOffset;
  late final AnimationController _enterController;
  late final Animation<double> _enterProgress;
  late final AnimationController _foundController;
  late final Animation<double> _foundProgress;
  Timer? _enterTimer;

  Color get _baseColor => getDigitDisplayColor(widget.digit.digit);

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _shakeOffset = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -7.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -7.0, end: 7.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 7.0, end: -5.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -5.0, end: 5.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 5.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut));

    _enterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: kFruitPopDurationMs),
    );
    _enterProgress = CurvedAnimation(
      parent: _enterController,
      curve: Curves.easeOutBack,
    );

    _foundController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: digitFoundVanishMs),
    );
    _foundProgress = CurvedAnimation(
      parent: _foundController,
      curve: Curves.easeOutBack,
    );

    _scheduleEnterAnimation();

    if (widget.state == DigitChipState.wrong) {
      _shakeController.forward(from: 0);
    }
    if (widget.state == DigitChipState.found) {
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
  void didUpdateWidget(_DigitChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != DigitChipState.wrong &&
        widget.state == DigitChipState.wrong) {
      _shakeController.forward(from: 0);
    }
    if (oldWidget.state != DigitChipState.found &&
        widget.state == DigitChipState.found) {
      _foundController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _enterTimer?.cancel();
    _shakeController.dispose();
    _enterController.dispose();
    _foundController.dispose();
    super.dispose();
  }

  Color get _textColor {
    if (widget.state == DigitChipState.wrong) {
      return const Color(0xFFDC2626);
    }
    return _baseColor;
  }

  @override
  Widget build(BuildContext context) {
    final isFound = widget.state == DigitChipState.found;
    final half = widget.chipSize / 2;

    return Transform.translate(
      offset: Offset(-half, -half),
      child: SizedBox(
        width: widget.chipSize,
        height: widget.chipSize,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            if (isFound)
              DigitFoundBurst(
                color: _baseColor,
                size: widget.chipSize,
              ),
            AnimatedBuilder(
              animation: Listenable.merge([
                _shakeController,
                _enterProgress,
                _foundProgress,
              ]),
              builder: (context, child) {
                final enterT = _enterProgress.value.clamp(0.0, 1.0);
                final foundT = _foundProgress.value.clamp(0.0, 1.0);
                final opacity = isFound ? (1 - foundT).clamp(0.0, 1.0) : enterT;
                final scale = isFound
                    ? 1 + 0.15 * foundT
                    : 0.88 + 0.12 * enterT;

                return Opacity(
                  opacity: opacity,
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
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.disabled || isFound ? null : widget.onTap,
                  customBorder: const CircleBorder(),
                  child: SizedBox(
                    width: widget.chipSize,
                    height: widget.chipSize,
                    child: Center(
                      child: Text(
                        '${widget.digit.digit}',
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
            ),
          ],
        ),
      ),
    );
  }
}
