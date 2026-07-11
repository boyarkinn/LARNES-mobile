import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:larnes_mobile/trainers/reading/letter_name_aloud/name_aloud_sizes.dart';

const _popCurve = Cubic(0.34, 1.2, 0.64, 1);
const _letterSwitchMs = 350;

/// Web: `platform/src/trainers/reading/letter-name-aloud/name-aloud-scene.tsx`
class NameAloudScene extends StatefulWidget {
  const NameAloudScene({
    super.key,
    required this.displayPulseActive,
    required this.letter,
    required this.letterColor,
    required this.letterKey,
    this.settlePulseActive = false,
  });

  final bool displayPulseActive;
  final bool settlePulseActive;
  final String letter;
  final Color letterColor;
  final String letterKey;

  @override
  State<NameAloudScene> createState() => _NameAloudSceneState();
}

class _NameAloudSceneState extends State<NameAloudScene>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this);
    _syncPulse();
  }

  @override
  void didUpdateWidget(NameAloudScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.displayPulseActive != widget.displayPulseActive ||
        oldWidget.settlePulseActive != widget.settlePulseActive) {
      _syncPulse();
    }
  }

  void _syncPulse() {
    _pulseController.stop();

    if (widget.settlePulseActive) {
      _pulseController
        ..duration = const Duration(milliseconds: nameAloudSettlePulseMs)
        ..repeat(reverse: true);
      return;
    }

    if (widget.displayPulseActive) {
      _pulseController
        ..duration = const Duration(milliseconds: nameAloudDisplayPulseMs)
        ..repeat(reverse: true);
      return;
    }

    _pulseController.value = 0;
  }

  @override
  void dispose() {
    _pulseController.stop();
    _pulseController.dispose();
    super.dispose();
  }

  double _pulseScale() {
    if (!widget.displayPulseActive && !widget.settlePulseActive) {
      return 1;
    }

    final t = _pulseController.value.clamp(0.0, 1.0);
    return 1 + 0.04 * math.sin(t * math.pi);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxSize = nameAloudBoxSize(
          constraints.maxHeight,
          constraints.maxWidth,
        );
        final fontSize = nameAloudLetterFontSize(
          constraints.maxHeight,
          constraints.maxWidth,
        );

        return AnimatedBuilder(
          animation: _pulseController,
          builder: (context, _) {
            return Transform.scale(
              scale: _pulseScale(),
              alignment: Alignment.center,
              child: SizedBox(
                width: boxSize,
                height: boxSize,
                child: Center(
                  child: TweenAnimationBuilder<double>(
                    key: ValueKey(widget.letterKey),
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: _letterSwitchMs),
                    curve: _popCurve,
                    builder: (context, value, child) {
                      final progress = value.clamp(0.0, 1.0);

                      return Opacity(
                        opacity: progress,
                        child: Transform.scale(
                          scale: 0.88 + 0.12 * progress,
                          child: child,
                        ),
                      );
                    },
                    child: Text(
                      widget.letter,
                      style: GoogleFonts.onest(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w700,
                        color: widget.letterColor,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
