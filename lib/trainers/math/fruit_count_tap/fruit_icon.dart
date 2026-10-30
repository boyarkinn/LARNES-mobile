import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/math/fruit_count_tap/fruit_artwork.dart';
import 'package:larnes_mobile/trainers/math/fruit_count_tap/fruit_count_tap_model.dart';

/// The same local PNG artwork as the Web FruitIcon; no asset configuration needed.
class FruitIcon extends StatelessWidget {
  const FruitIcon({
    super.key,
    required this.fruit,
    this.size = 40,
  });

  final FruitSlug fruit;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.memory(
        fruitArtworkBytes(fruit),
        width: size,
        height: size,
        fit: BoxFit.contain,
        excludeFromSemantics: true,
        filterQuality: FilterQuality.medium,
      ),
    );
  }
}
