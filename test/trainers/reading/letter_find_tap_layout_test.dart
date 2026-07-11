import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/reading/letter_colors.dart';
import 'package:larnes_mobile/trainers/reading/letter_find_tap/letter_find_tap_layout.dart';
import 'package:larnes_mobile/trainers/reading/letter_find_tap/letter_find_tap_model.dart';
import 'package:larnes_mobile/trainers/shared/seeded_rng.dart';

void main() {
  group('assignLetterDisplayColors', () {
    test('assigns palette colors to every token', () {
      final rng = createSeededRng(5);
      final tokens = buildLetterTokens(
        BuildLetterFieldInput(
          distractorCount: 2,
          letterCase: 'upper',
          rng: rng,
          targetCount: 2,
          targetLetter: 'В',
        ),
      );

      final colored = assignLetterDisplayColors(tokens, createSeededRng(9));

      expect(colored.length, tokens.length);
      expect(
        colored.every(
          (token) =>
              token.displayColor != null &&
              letterColorPalette.contains(token.displayColor),
        ),
        isTrue,
      );
    });
  });

  group('placeLetterTokens', () {
    test('places every token without overlap', () {
      final rng = createSeededRng(123);
      final tokens = buildLetterTokens(
        BuildLetterFieldInput(
          distractorCount: 10,
          letterCase: 'upper',
          rng: rng,
          targetCount: 4,
          targetLetter: 'С',
        ),
      );
      final placed = placeLetterTokens(tokens, rng);

      expect(placed.length, tokens.length);

      for (var index = 0; index < placed.length; index++) {
        for (var otherIndex = index + 1; otherIndex < placed.length; otherIndex++) {
          final first = placed[index];
          final second = placed[otherIndex];
          final distance = math.sqrt(
            math.pow(first.xPercent - second.xPercent, 2) +
                math.pow(first.yPercent - second.yPercent, 2),
          );

          expect(distance, greaterThanOrEqualTo(letterFieldMinDistancePercent));
        }
      }
    });
  });
}
