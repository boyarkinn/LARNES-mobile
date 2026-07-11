import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:larnes_mobile/trainers/math/fruit_count_tap/fruit_reveal.dart';
import 'package:larnes_mobile/trainers/reading/letter_orientation_pick/orientation_pick_model.dart';
import 'package:larnes_mobile/trainers/reading/letter_orientation_pick/orientation_pick_size.dart';

const _popCurve = Cubic(0.34, 1.2, 0.64, 1);
const _foundGreen = Color(0xFF16A34A);
const _wrongRed = Color(0xFFDC2626);

enum OrientationOptionState { normal, found, wrong }

/// Web: `platform/src/trainers/reading/letter-orientation-pick/orientation-board.tsx`
class OrientationBoard extends StatelessWidget {
  const OrientationBoard({
    super.key,
    required this.options,
    required this.displayColor,
    required this.disabled,
    required this.isRevealComplete,
    required this.selectedId,
    required this.wrongId,
    required this.onSelect,
  });

  final List<OrientationOption> options;
  final Color displayColor;
  final bool disabled;
  final bool isRevealComplete;
  final String? selectedId;
  final String? wrongId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final optionCount = options.length;
        final crossAxisCount = getOrientationPickGridCrossAxisCount(
          optionCount,
          constraints.maxWidth,
        );
        final tileSize = getOrientationPickTileSizePx(
          constraints.maxHeight,
          constraints.maxWidth,
        );
        final fontSize = getOrientationPickLetterFontSizePx(
          constraints.maxHeight,
          constraints.maxWidth,
        );

        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemCount: optionCount,
              itemBuilder: (context, index) {
                final option = options[index];
                final state = selectedId == option.id && option.isUpright
                    ? OrientationOptionState.found
                    : wrongId == option.id
                        ? OrientationOptionState.wrong
                        : OrientationOptionState.normal;

                return Center(
                  child: SizedBox(
                    width: tileSize,
                    height: tileSize,
                    child: _OrientationOptionCard(
                      key: ValueKey(option.id),
                      option: option,
                      displayColor: displayColor,
                      fontSize: fontSize,
                      disabled: disabled || !isRevealComplete,
                      revealDelayMs: getFruitRevealDelayMs(index, optionCount),
                      state: state,
                      onSelect: () => onSelect(option.id),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _OrientationOptionCard extends StatefulWidget {
  const _OrientationOptionCard({
    super.key,
    required this.option,
    required this.displayColor,
    required this.fontSize,
    required this.disabled,
    required this.revealDelayMs,
    required this.state,
    required this.onSelect,
  });

  final OrientationOption option;
  final Color displayColor;
  final double fontSize;
  final bool disabled;
  final int revealDelayMs;
  final OrientationOptionState state;
  final VoidCallback onSelect;

  @override
  State<_OrientationOptionCard> createState() => _OrientationOptionCardState();
}

class _OrientationOptionCardState extends State<_OrientationOptionCard>
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
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -7.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -7.0, end: 7.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 7.0, end: -5.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -5.0, end: 5.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 5.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut));

    _foundController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _foundScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.12), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.12, end: 1.0), weight: 1),
    ]).animate(_foundController);

    _scheduleEnterAnimation();

    if (widget.state == OrientationOptionState.wrong) {
      _shakeController.forward(from: 0);
    }
    if (widget.state == OrientationOptionState.found) {
      _foundController.forward(from: 0);
    }
  }

  void _scheduleEnterAnimation() {
    if (widget.revealDelayMs <= 0) {
      _enterController.value = 1;
      return;
    }

    _enterTimer = Timer(Duration(milliseconds: widget.revealDelayMs), () {
      if (mounted) {
        _enterController.forward();
      }
    });
  }

  @override
  void didUpdateWidget(_OrientationOptionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != OrientationOptionState.wrong &&
        widget.state == OrientationOptionState.wrong) {
      _shakeController.forward(from: 0);
    }
    if (oldWidget.state != OrientationOptionState.found &&
        widget.state == OrientationOptionState.found) {
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

  Color get _letterColor {
    switch (widget.state) {
      case OrientationOptionState.wrong:
        return _wrongRed;
      case OrientationOptionState.found:
        return _foundGreen;
      case OrientationOptionState.normal:
        return widget.displayColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFound = widget.state == OrientationOptionState.found;

    return AnimatedBuilder(
      animation: Listenable.merge([
        _enterProgress,
        _shakeController,
        _foundController,
      ]),
      builder: (context, child) {
        final enterT = _enterProgress.value.clamp(0.0, 1.0);
        final scale = isFound
            ? _foundScale.value.clamp(0.88, 1.12)
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
          onTap: widget.disabled || isFound ? null : widget.onSelect,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Center(
              child: Transform.rotate(
                angle: widget.option.rotationDeg * pi / 180,
                child: Text(
                  widget.option.letter,
                  style: GoogleFonts.onest(
                    fontSize: widget.fontSize,
                    fontWeight: FontWeight.w700,
                    height: 1,
                    color: _letterColor,
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
