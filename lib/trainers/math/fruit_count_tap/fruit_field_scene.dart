import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/math/fruit_count_tap/fruit_count_tap_layout.dart';
import 'package:larnes_mobile/trainers/math/fruit_count_tap/fruit_icon.dart';

class FruitFieldScene extends StatelessWidget {
  const FruitFieldScene({
    super.key,
    required this.fruits,
  });

  final List<PlacedFruit> fruits;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 5 / 4,
      child: Container(
        constraints: const BoxConstraints(minHeight: 260),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xCCD1FAE5), Colors.white],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFD1FAE5)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              clipBehavior: Clip.none,
              children: [
                for (final fruit in fruits)
                  Positioned(
                    left: fruit.xPercent / 100 * constraints.maxWidth,
                    top: fruit.yPercent / 100 * constraints.maxHeight,
                    child: Transform.translate(
                      offset: const Offset(-21, -21),
                      child: Transform.rotate(
                        angle: fruit.rotationDeg * math.pi / 180,
                        child: IgnorePointer(
                          child: FruitIcon(
                            fruit: fruit.fruit,
                            size: 42,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
