import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/flashcard_digit_match/match_grid_layout.dart';

void main() {
  group('getMatchGridSlotLayout', () {
    test('places two left items in the first column', () {
      expect(
        getMatchGridSlotLayout(index: 0, count: 2, side: MatchSide.left).column,
        0,
      );
      expect(
        getMatchGridSlotLayout(index: 0, count: 2, side: MatchSide.left).row,
        0,
      );
      expect(
        getMatchGridSlotLayout(index: 1, count: 2, side: MatchSide.left).row,
        1,
      );
    });

    test('places three left items with the third centered in the second column', () {
      final third = getMatchGridSlotLayout(index: 2, count: 3, side: MatchSide.left);

      expect(third.column, 1);
      expect(third.rowSpan, 2);
    });

    test('fills a 2x2 grid for four left items', () {
      final slots = List.generate(
        4,
        (index) => getMatchGridSlotLayout(index: index, count: 4, side: MatchSide.left),
      );

      expect(slots[0].column, 0);
      expect(slots[0].row, 0);
      expect(slots[1].row, 1);
      expect(slots[2].column, 1);
      expect(slots[2].row, 0);
      expect(slots[3].row, 1);
    });

    test('mirrors placement on the right side', () {
      expect(
        getMatchGridSlotLayout(index: 0, count: 2, side: MatchSide.right).column,
        1,
      );
      expect(
        getMatchGridSlotLayout(index: 2, count: 3, side: MatchSide.right).column,
        0,
      );
      expect(
        getMatchGridSlotLayout(index: 2, count: 3, side: MatchSide.right).rowSpan,
        2,
      );
    });
  });

  group('computeMatchBoardLayout', () {
    test('fits the two-row grid inside a portrait stage', () {
      final layout = computeMatchBoardLayout(
        viewportWidth: 360,
        viewportHeight: 580,
      );

      expect(layout.totalHeight, lessThanOrEqualTo(580));
      expect(layout.abacusHeight, lessThanOrEqualTo(layout.rowHeight));
      expect(layout.digitSize, lessThanOrEqualTo(layout.rowHeight));
    });

    test('shrinks rows to fit a landscape stage', () {
      final layout = computeMatchBoardLayout(
        viewportWidth: 780,
        viewportHeight: 360,
      );

      expect(layout.totalHeight, lessThanOrEqualTo(360));
      expect(layout.rowHeight, lessThan(18.75 * 16));
      expect(layout.abacusHeight, lessThanOrEqualTo(layout.rowHeight));
    });

    test('keeps digit font inside the target box', () {
      final layout = computeMatchBoardLayout(
        viewportWidth: 320,
        viewportHeight: 480,
      );

      expect(layout.digitFontSize, lessThanOrEqualTo(layout.digitSize));
    });
  });
}
