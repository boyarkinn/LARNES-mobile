import 'dart:math' as math;

import 'package:larnes_mobile/trainers/reading/letter_find_tap/letter_find_tap_model.dart';

/// Web: `platform/src/trainers/reading/letter-find-tap/layout.ts`

const letterFieldMaxPlacementAttempts = 80;
const letterFieldMinDistancePercent = 16.0;
const letterFieldPaddingPercent = 10.0;

class PlacedLetter extends LetterToken {
  const PlacedLetter({
    required super.letter,
    required super.id,
    required super.isTarget,
    super.displayColor,
    required this.xPercent,
    required this.yPercent,
  });

  final double xPercent;
  final double yPercent;
}

List<PlacedLetter> placeLetterTokens(
  List<LetterToken> tokens,
  double Function() rng,
) {
  final placed = <PlacedLetter>[];
  final span = 100 - letterFieldPaddingPercent * 2;

  for (final token in tokens) {
    var positioned = false;

    for (var attempt = 0; attempt < letterFieldMaxPlacementAttempts; attempt++) {
      final xPercent = letterFieldPaddingPercent + rng() * span;
      final yPercent = letterFieldPaddingPercent + rng() * span;
      final hasOverlap = placed.any(
        (existing) =>
            _distancePercent(
              xPercent,
              yPercent,
              existing.xPercent,
              existing.yPercent,
            ) <
            letterFieldMinDistancePercent,
      );

      if (!hasOverlap) {
        placed.add(
          PlacedLetter(
            letter: token.letter,
            id: token.id,
            isTarget: token.isTarget,
            displayColor: token.displayColor,
            xPercent: xPercent,
            yPercent: yPercent,
          ),
        );
        positioned = true;
        break;
      }
    }

    if (!positioned) {
      throw StateError('LETTER_FIELD_PLACEMENT_FAILED');
    }
  }

  return placed;
}

double _distancePercent(double x1, double y1, double x2, double y2) {
  final dx = x2 - x1;
  final dy = y2 - y1;
  return math.sqrt(dx * dx + dy * dy);
}
