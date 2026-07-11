import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/math/fruit_count_tap/fruit_count_tap_layout.dart';
import 'package:larnes_mobile/trainers/math/fruit_count_tap/fruit_icon.dart';
import 'package:larnes_mobile/trainers/math/fruit_count_tap/fruit_icon_size.dart';
import 'package:larnes_mobile/trainers/math/fruit_count_tap/fruit_reveal.dart';

/// Web v2: `platform/src/trainers/math/fruit-count-tap/fruit-field-scene.tsx`
class FruitFieldScene extends StatelessWidget {
  const FruitFieldScene({
    super.key,
    required this.fruits,
  });

  final List<PlacedFruit> fruits;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final iconSize = getFruitIconSizePx(constraints.maxHeight);
        final fruitCount = fruits.length;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            for (var index = 0; index < fruits.length; index++)
              Positioned(
                left: fruits[index].xPercent / 100 * constraints.maxWidth,
                top: fruits[index].yPercent / 100 * constraints.maxHeight,
                child: _StaggeredFruitToken(
                  fruit: fruits[index],
                  iconSize: iconSize,
                  enterDelayMs: getFruitRevealDelayMs(index, fruitCount),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _StaggeredFruitToken extends StatefulWidget {
  const _StaggeredFruitToken({
    required this.fruit,
    required this.iconSize,
    required this.enterDelayMs,
  });

  final PlacedFruit fruit;
  final double iconSize;
  final int enterDelayMs;

  @override
  State<_StaggeredFruitToken> createState() => _StaggeredFruitTokenState();
}

class _StaggeredFruitTokenState extends State<_StaggeredFruitToken>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progress;
  Timer? _enterTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: kFruitPopDurationMs),
    );
    _progress = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    if (widget.enterDelayMs <= 0) {
      _controller.value = 1;
      return;
    }

    _enterTimer = Timer(Duration(milliseconds: widget.enterDelayMs), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _enterTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final half = widget.iconSize / 2;

    return AnimatedBuilder(
      animation: _progress,
      builder: (context, child) {
        final t = _progress.value.clamp(0.0, 1.0);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(-half, -half),
            child: Transform.rotate(
              angle: widget.fruit.rotationDeg * math.pi / 180,
              child: Transform.scale(
                scale: 0.88 + 0.12 * t,
                child: child,
              ),
            ),
          ),
        );
      },
      child: IgnorePointer(
        child: FruitIcon(
          fruit: widget.fruit.fruit,
          size: widget.iconSize,
        ),
      ),
    );
  }
}
