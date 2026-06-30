import 'dart:math' as math;

import 'package:larnes_mobile/trainers/math/digit_find_tap/digit_find_tap_model.dart';

const digitFieldMaxPlacementAttempts = 80;
const digitFieldMinDistancePercent = 11.0;
const digitFieldPaddingPercent = 10.0;

class PlacedDigit extends DigitToken {
  const PlacedDigit({
    required super.digit,
    required super.id,
    required super.isTarget,
    required this.xPercent,
    required this.yPercent,
  });

  final double xPercent;
  final double yPercent;
}

List<PlacedDigit> placeDigitTokens(
  List<DigitToken> tokens,
  double Function() rng,
) {
  final placed = <PlacedDigit>[];
  final span = 100 - digitFieldPaddingPercent * 2;

  for (final token in tokens) {
    var positioned = false;

    for (var attempt = 0; attempt < digitFieldMaxPlacementAttempts; attempt++) {
      final xPercent = digitFieldPaddingPercent + rng() * span;
      final yPercent = digitFieldPaddingPercent + rng() * span;
      final hasOverlap = placed.any(
        (existing) =>
            _distancePercent(
              xPercent,
              yPercent,
              existing.xPercent,
              existing.yPercent,
            ) <
            digitFieldMinDistancePercent,
      );

      if (!hasOverlap) {
        placed.add(
          PlacedDigit(
            digit: token.digit,
            id: token.id,
            isTarget: token.isTarget,
            xPercent: xPercent,
            yPercent: yPercent,
          ),
        );
        positioned = true;
        break;
      }
    }

    if (!positioned) {
      throw StateError('DIGIT_FIELD_PLACEMENT_FAILED');
    }
  }

  return placed;
}

double _distancePercent(double x1, double y1, double x2, double y2) {
  final dx = x2 - x1;
  final dy = y2 - y1;
  return math.sqrt(dx * dx + dy * dy);
}
