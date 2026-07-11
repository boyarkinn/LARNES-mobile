import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/math/fruit_count_tap/fruit_reveal.dart';
import 'package:larnes_mobile/trainers/reading/letter_grid_match/grid_match_reveal.dart';

void main() {
  group('grid_match_reveal', () {
    test('matches web reference reveal stagger', () {
      expect(getReferenceRevealStaggerMs(1), 0);
      expect(
        getReferenceRevealStaggerMs(4),
        ((gridReferenceRevealBudgetMs - fruitPopDurationMs) / 3).floor(),
      );
    });

    test('chains target grid and pool reveal after reference', () {
      const filledCount = 4;
      const poolCount = 4;

      expect(
        getTargetGridRevealStartMs(filledCount),
        getReferenceRevealTotalMs(filledCount) + targetGridRevealGapMs,
      );
      expect(
        getPoolRevealStartMs(filledCount),
        getTargetGridRevealStartMs(filledCount) + targetGridPopMs,
      );
      expect(
        getGridMatchInteractionReadyMs(filledCount, poolCount),
        getPoolRevealStartMs(filledCount) + getAnswerRevealTotalMs(poolCount),
      );
    });

    test('getReferenceRevealDelayMs scales by filled index', () {
      const filledCount = 5;
      final stagger = getReferenceRevealStaggerMs(filledCount);

      expect(getReferenceRevealDelayMs(0, filledCount), 0);
      expect(getReferenceRevealDelayMs(2, filledCount), stagger * 2);
    });
  });
}
