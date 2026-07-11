import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/math/fruit_count_tap/fruit_reveal.dart';
import 'package:larnes_mobile/trainers/shared/trainer_constants.dart';

void main() {
  group('getFruitRevealStaggerMs', () {
    test('returns zero for a single fruit', () {
      expect(getFruitRevealStaggerMs(1), 0);
    });

    test('spreads stagger across the total budget', () {
      expect(getFruitRevealStaggerMs(20), ((2000 - 250) / 19).floor());
    });
  });

  group('getFruitRevealTotalMs', () {
    test('returns zero for an empty field', () {
      expect(getFruitRevealTotalMs(0), 0);
    });

    test('uses only pop duration for one fruit', () {
      expect(getFruitRevealTotalMs(1), kFruitPopDurationMs);
    });

    test('never exceeds the reveal budget for typical field sizes', () {
      for (var count = 1; count <= maxFruitFieldTokens; count++) {
        expect(
          getFruitRevealTotalMs(count) <= fruitRevealTotalBudgetMs,
          isTrue,
        );
      }
    });
  });

  group('getFruitRevealDelayMs', () {
    test('staggers each fruit by index', () {
      const count = 5;
      final stagger = getFruitRevealStaggerMs(count);

      expect(getFruitRevealDelayMs(0, count), 0);
      expect(getFruitRevealDelayMs(3, count), stagger * 3);
    });
  });

  group('getAnswerRevealTotalMs', () {
    test('fits four answer buttons within the answer budget', () {
      expect(getAnswerRevealTotalMs(4) <= 700, isTrue);
      expect(
        getAnswerRevealTotalMs(4),
        getAnswerRevealStaggerMs(4) * 3 + kFruitPopDurationMs,
      );
    });
  });
}
