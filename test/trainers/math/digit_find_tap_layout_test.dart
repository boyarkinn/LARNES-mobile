import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/math/digit_find_tap/digit_find_tap_layout.dart';
import 'package:larnes_mobile/trainers/math/digit_find_tap/digit_find_tap_model.dart';
import 'package:larnes_mobile/trainers/shared/seeded_rng.dart';

void main() {
  group('placeDigitTokens', () {
    test('places every token inside the field', () {
      final rng = createSeededRng(7);
      final tokens = buildDigitTokens(
        BuildDigitFieldInput(
          distractorCount: 10,
          rng: rng,
          targetCount: 3,
          targetDigit: 1,
        ),
      );
      final placed = placeDigitTokens(tokens, rng);

      expect(placed.length, tokens.length);
      expect(
        placed.every(
          (digit) => digit.xPercent >= 10 && digit.xPercent <= 90,
        ),
        isTrue,
      );
      expect(
        placed.every(
          (digit) => digit.yPercent >= 10 && digit.yPercent <= 90,
        ),
        isTrue,
      );
    });
  });
}
