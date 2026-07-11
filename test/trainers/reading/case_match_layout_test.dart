import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/flashcard_digit_match/match_grid_layout.dart';
import 'package:larnes_mobile/trainers/reading/letter_case_match/case_match_layout.dart';

void main() {
  group('usesCaseMatchGridLayout', () {
    test('uses grid for 2 to 4 pairs', () {
      expect(usesCaseMatchGridLayout(2), isTrue);
      expect(usesCaseMatchGridLayout(4), isTrue);
      expect(usesCaseMatchGridLayout(5), isFalse);
    });
  });

  group('getCaseMatchGridSlotLayout', () {
    test('delegates to flashcard match grid slots', () {
      final layout = getCaseMatchGridSlotLayout(
        index: 0,
        count: 3,
        side: MatchSide.left,
      );
      final expected = getMatchGridSlotLayout(
        index: 0,
        count: 3,
        side: MatchSide.left,
      );

      expect(layout.column, expected.column);
      expect(layout.row, expected.row);
      expect(layout.columnSpan, expected.columnSpan);
      expect(layout.rowSpan, expected.rowSpan);
      expect(layout.alignment, expected.alignment);
    });
  });
}
