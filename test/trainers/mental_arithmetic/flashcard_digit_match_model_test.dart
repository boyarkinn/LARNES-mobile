import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/flashcard_digit_match/flashcard_digit_match_model.dart';

void main() {
  group('areValuesValid', () {
    test('accepts unique values within rods', () {
      expect(areValuesValid([0, 1, 2], 1), isTrue);
    });

    test('rejects duplicates', () {
      expect(areValuesValid([1, 1, 2], 1), isFalse);
    });

    test('rejects values above rod capacity', () {
      expect(areValuesValid([0, 10], 1), isFalse);
    });
  });

  group('buildMatchRound', () {
    test('shuffles both columns deterministically', () {
      final first = buildMatchRound([0, 1, 2], 42);
      final second = buildMatchRound([0, 1, 2], 42);

      expect(first.leftItems.length, 3);
      expect(first.rightItems.length, 3);
      expect(first.leftItems.map((item) => item.id).toList(),
          second.leftItems.map((item) => item.id).toList());
      expect(first.rightItems.map((item) => item.id).toList(),
          second.rightItems.map((item) => item.id).toList());
    });
  });

  group('connections', () {
    test('checks matching values', () {
      expect(isCorrectConnection(3, 3), isTrue);
      expect(isCorrectConnection(3, 4), isFalse);
    });

    test('detects completed round', () {
      const values = [0, 1, 2];

      expect(
        isRoundComplete(
          [
            const MatchConnection(leftId: 'a', rightId: 'b', value: 0),
            const MatchConnection(leftId: 'c', rightId: 'd', value: 1),
          ],
          values,
        ),
        isFalse,
      );

      expect(
        isRoundComplete(
          [
            const MatchConnection(leftId: 'left-0', rightId: 'right-0', value: 0),
            const MatchConnection(leftId: 'left-1', rightId: 'right-1', value: 1),
            const MatchConnection(leftId: 'left-2', rightId: 'right-2', value: 2),
          ],
          values,
        ),
        isTrue,
      );
    });
  });

  group('parseMatchValuesFromInput', () {
    test('reads pairCount and value fields', () {
      expect(
        parseMatchValuesFromInput(
          pairCount: 3,
          value0: 4,
          value1: 1,
          value2: 7,
          value3: 9,
        ),
        [4, 1, 7],
      );
    });
  });
}
