import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/math/fruit_count_tap/fruit_count_tap_model.dart';
import 'package:larnes_mobile/trainers/shared/seeded_rng.dart';
import 'package:larnes_mobile/trainers/shared/trainer_constants.dart';

void main() {
  group('getAnswerChoices', () {
    test('returns four consecutive digits', () {
      expect(getAnswerChoices(4), [4, 5, 6, 7]);
    });
  });

  group('isTargetCountInAnswerRange', () {
    test('checks inclusion in four-button range', () {
      expect(isTargetCountInAnswerRange(3, 2), isTrue);
      expect(isTargetCountInAnswerRange(8, 2), isFalse);
    });
  });

  group('canFitFruitField', () {
    test('accepts valid combinations', () {
      expect(canFitFruitField(3, 4, 20), isTrue);
    });

    test('rejects too few fruits for types', () {
      expect(canFitFruitField(3, 4, 5), isFalse);
    });
  });

  group('buildFruitTokens', () {
    test('creates the requested target and total counts', () {
      final rng = createSeededRng(11);
      final tokens = buildFruitTokens(
        BuildFruitFieldInput(
          answerRangeStart: 2,
          fruitTypeCount: 4,
          rng: rng,
          targetCount: 3,
          targetFruit: 'watermelon',
          totalFruits: 18,
        ),
      );

      expect(tokens.length, 18);
      expect(tokens.where((token) => token.isTarget).length, 3);
      expect(
        tokens.where((token) => token.fruit == 'watermelon').length,
        3,
      );
      expect(tokens.map((token) => token.fruit).toSet().length, 4);
    });

    test('supports zero target fruits', () {
      final rng = createSeededRng(5);
      final tokens = buildFruitTokens(
        BuildFruitFieldInput(
          answerRangeStart: 0,
          fruitTypeCount: 2,
          rng: rng,
          targetCount: 0,
          targetFruit: 'apple',
          totalFruits: 10,
        ),
      );

      expect(tokens.where((token) => token.fruit == 'apple').length, 0);
      expect(tokens.length, 10);
    });
  });
}
