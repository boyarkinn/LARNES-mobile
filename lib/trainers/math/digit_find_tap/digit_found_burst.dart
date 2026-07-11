import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Web v2: `platform/src/trainers/math/digit-find-tap/digit-found-burst.tsx`

const digitFoundBurstMs = 520;
const digitFoundBurstSparkCount = 8;
const digitFoundVanishMs = 380;

class DigitFoundBurst extends StatefulWidget {
  const DigitFoundBurst({
    super.key,
    required this.color,
    required this.size,
  });

  final Color color;
  final double size;

  @override
  State<DigitFoundBurst> createState() => _DigitFoundBurstState();
}

class _DigitFoundBurstState extends State<DigitFoundBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: digitFoundBurstMs),
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
            for (var index = 0; index < digitFoundBurstSparkCount; index++)
              Transform.translate(
                offset: Offset(
                  math.cos((index / digitFoundBurstSparkCount) * math.pi * 2) *
                      travel *
                      t,
                  math.sin((index / digitFoundBurstSparkCount) * math.pi * 2) *
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
