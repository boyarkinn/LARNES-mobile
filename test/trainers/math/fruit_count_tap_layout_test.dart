import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/math/fruit_count_tap/fruit_count_tap_layout.dart';
import 'package:larnes_mobile/trainers/math/fruit_count_tap/fruit_count_tap_model.dart';
import 'package:larnes_mobile/trainers/shared/seeded_rng.dart';

void main() {
  group('placeFruitTokens', () {
    test('places every fruit inside the field', () {
      final rng = createSeededRng(3);
      final tokens = buildFruitTokens(
        BuildFruitFieldInput(
          answerRangeStart: 1,
          fruitTypeCount: 3,
          rng: rng,
          targetCount: 2,
          targetFruit: 'banana',
          totalFruits: 15,
        ),
      );
      final placed = placeFruitTokens(tokens, rng);

      expect(placed.length, 15);
      expect(
        placed.every((fruit) => fruit.xPercent >= 8 && fruit.xPercent <= 92),
        isTrue,
      );
      expect(
        placed.every((fruit) => fruit.yPercent >= 8 && fruit.yPercent <= 92),
        isTrue,
      );
    });
  });
}
