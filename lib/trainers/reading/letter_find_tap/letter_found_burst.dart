import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Web: `platform/src/trainers/reading/letter-marquee-tap/letter-found-burst.tsx`

const letterFoundBurstMs = 520;
const letterFoundBurstSparkCount = 8;
const letterFoundVanishMs = 380;

class LetterFoundBurst extends StatefulWidget {
  const LetterFoundBurst({
    super.key,
    required this.color,
    required this.size,
  });

  final Color color;
  final double size;

  @override
  State<LetterFoundBurst> createState() => _LetterFoundBurstState();
}

class _LetterFoundBurstState extends State<LetterFoundBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: letterFoundBurstMs),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sparkSize = math.max(6.0, widget.size * 0.14).roundToDouble();
    final travel = widget.size * 0.95;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeOut.transform(_controller.value.clamp(0.0, 1.0));
        final opacity = t < 0.65 ? 1.0 : (1 - ((t - 0.65) / 0.35)).clamp(0.0, 1.0);
        final scale = 1 + 0.15 * t - 0.8 * math.max(0, t - 0.65);

        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            for (var index = 0; index < letterFoundBurstSparkCount; index++)
              Transform.translate(
                offset: Offset(
                  math.cos((index / letterFoundBurstSparkCount) * math.pi * 2) *
                      travel *
                      t,
                  math.sin((index / letterFoundBurstSparkCount) * math.pi * 2) *
                      travel *
                      t,
                ),
                child: Opacity(
                  opacity: opacity,
                  child: Transform.scale(
                    scale: scale,
                    child: Container(
                      width: sparkSize,
                      height: sparkSize,
                      decoration: BoxDecoration(
                        color: widget.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
