import 'dart:async';

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/math/fruit_count_tap/fruit_reveal.dart';
import 'package:larnes_mobile/trainers/reading/letter_find_tap/letter_chip_size.dart';
import 'package:larnes_mobile/trainers/reading/letter_find_tap/letter_find_tap_layout.dart';
import 'package:larnes_mobile/trainers/reading/letter_find_tap/letter_found_burst.dart';

enum LetterChipState { normal, found, wrong }

Color letterDisplayColorFromHex(String? hex) {
  const fallback = Color(0xFF7C3AED);
  if (hex == null || hex.isEmpty) {
    return fallback;
  }

  final normalized = hex.startsWith('#') ? hex.substring(1) : hex;
  if (normalized.length != 6) {
    return fallback;
  }

  final value = int.tryParse(normalized, radix: 16);
  if (value == null) {
    return fallback;
  }

  return Color(0xFF000000 | value);
}

/// Web v2: `platform/src/trainers/reading/letter-find-tap/letter-field-scene.tsx`
class LetterFieldScene extends StatelessWidget {
  const LetterFieldScene({
    super.key,
    required this.letters,
    required this.disabled,
    required this.foundIds,
    required this.onTap,
    required this.wrongId,
  });

  final List<PlacedLetter> letters;
  final bool disabled;
  final Set<String> foundIds;
  final ValueChanged<String> onTap;
  final String? wrongId;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final chipSize = getLetterChipSizePx(constraints.maxHeight);
        final fontSize = getLetterChipFontSizePx(chipSize);
        final letterCount = letters.length;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            for (var index = 0; index < letters.length; index++)
              Positioned(
                left: letters[index].xPercent / 100 * constraints.maxWidth,
                top: letters[index].yPercent / 100 * constraints.maxHeight,
                child: _LetterChip(
                  key: ValueKey(letters[index].id),
                  letter: letters[index],
                  chipSize: chipSize,
                  fontSize: fontSize,
                  disabled: disabled,
                  enterDelayMs: getFruitRevealDelayMs(index, letterCount),
                  state: foundIds.contains(letters[index].id)
                      ? LetterChipState.found
                      : wrongId == letters[index].id
                          ? LetterChipState.wrong
                          : LetterChipState.normal,
                  onTap: () => onTap(letters[index].id),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _LetterChip extends StatefulWidget {
  const _LetterChip({
    super.key,
    required this.letter,
    required this.chipSize,
    required this.fontSize,
    required this.disabled,
    required this.enterDelayMs,
    required this.state,
    required this.onTap,
  });

  final PlacedLetter letter;
  final double chipSize;
  final double fontSize;
  final bool disabled;
  final int enterDelayMs;
  final LetterChipState state;
  final VoidCallback onTap;

  @override
  State<_LetterChip> createState() => _LetterChipState();
}

class _LetterChipState extends State<_LetterChip> with TickerProviderStateMixin {
  late final AnimationController _shakeController;
  late final Animation<double> _shakeOffset;
  late final AnimationController _enterController;
  late final Animation<double> _enterProgress;
  late final AnimationController _foundController;
  late final Animation<double> _foundProgress;
  Timer? _enterTimer;

  Color get _baseColor => letterDisplayColorFromHex(widget.letter.displayColor);

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
      duration: const Duration(milliseconds: letterFoundVanishMs),
    );
    _foundProgress = CurvedAnimation(
      parent: _foundController,
      curve: Curves.easeOutBack,
    );

    _scheduleEnterAnimation();

    if (widget.state == LetterChipState.wrong) {
      _shakeController.forward(from: 0);
    }
    if (widget.state == LetterChipState.found) {
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
  void didUpdateWidget(_LetterChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != LetterChipState.wrong &&
        widget.state == LetterChipState.wrong) {
      _shakeController.forward(from: 0);
    }
    if (oldWidget.state != LetterChipState.found &&
        widget.state == LetterChipState.found) {
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
    if (widget.state == LetterChipState.wrong) {
      return const Color(0xFFDC2626);
    }
    return _baseColor;
  }

  @override
  Widget build(BuildContext context) {
    final isFound = widget.state == LetterChipState.found;
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
              LetterFoundBurst(
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
                        widget.letter.letter,
                        style: TextStyle(
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
          ],
        ),
      ),
    );
  }
}
