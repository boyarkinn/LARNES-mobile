import 'dart:math' as math;

import 'package:larnes_mobile/trainers/math/fruit_count_tap/fruit_count_tap_model.dart';

const fruitFieldMaxPlacementAttempts = 100;
const fruitFieldMinDistancePercent = 9.0;
const fruitFieldPaddingPercent = 8.0;

class PlacedFruit extends FruitToken {
  const PlacedFruit({
    required super.fruit,
    required super.id,
    required super.isTarget,
    required this.rotationDeg,
    required this.xPercent,
    required this.yPercent,
  });

  final double rotationDeg;
  final double xPercent;
  final double yPercent;
}

List<PlacedFruit> placeFruitTokens(
  List<FruitToken> tokens,
  double Function() rng,
) {
  final placed = <PlacedFruit>[];
  final span = 100 - fruitFieldPaddingPercent * 2;

  for (final token in tokens) {
    var positioned = false;

    for (var attempt = 0; attempt < fruitFieldMaxPlacementAttempts; attempt++) {
      final xPercent = fruitFieldPaddingPercent + rng() * span;
      final yPercent = fruitFieldPaddingPercent + rng() * span;
      final hasOverlap = placed.any(
        (existing) =>
            _distancePercent(
              xPercent,
              yPercent,
              existing.xPercent,
              existing.yPercent,
            ) <
            fruitFieldMinDistancePercent,
      );

      if (!hasOverlap) {
        placed.add(
          PlacedFruit(
            fruit: token.fruit,
            id: token.id,
            isTarget: token.isTarget,
            rotationDeg: -18 + rng() * 36,
            xPercent: xPercent,
            yPercent: yPercent,
          ),
        );
        positioned = true;
        break;
      }
    }

    if (!positioned) {
      throw StateError('FRUIT_FIELD_PLACEMENT_FAILED');
    }
  }

  return placed;
}

double _distancePercent(double x1, double y1, double x2, double y2) {
  final dx = x2 - x1;
  final dy = y2 - y1;
  return math.sqrt(dx * dx + dy * dy);
}
