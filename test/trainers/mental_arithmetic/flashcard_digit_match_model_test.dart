import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/flashcard_digit_match/flashcard_digit_match_model.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/flashcard_digit_match/match_colors.dart';
import 'package:larnes_mobile/trainers/shared/seeded_rng.dart';

void main() {
  group('buildFlashcardMatchPlan', () {
    test('builds deterministic multi-round plans', () {
      final first = buildFlashcardMatchPlan(
        pairCount: 3,
        rounds: 2,
        totalRods: 1,
        masterSeed: 42,
      );
      final second = buildFlashcardMatchPlan(
        pairCount: 3,
        rounds: 2,
        totalRods: 1,
        masterSeed: 42,
      );

      expect(first.length, 2);
      expect(first, second);
      expect(first[0]!.values, isNot(first[1]!.values));
    });

    test('assigns different left and right colors per pair', () {
      final round = buildFlashcardMatchPlan(
        pairCount: 4,
        rounds: 1,
        totalRods: 1,
        masterSeed: 7,
      ).first;

      for (final item in round.leftItems) {
        expect(item.leftDisplayColor, isNot(item.rightDisplayColor));
      }

      final allColors = round.leftItems
          .expand((item) => [item.leftDisplayColor, item.rightDisplayColor])
          .toSet();

      expect(allColors.length, 8);
    });
  });

  group('buildMatchRound', () {
    test('shuffles both columns deterministically', () {
      final colorPairs = pickMatchColorPairs(3, createSeededRng(11));
      final first = buildMatchRound([0, 1, 2], 42, colorPairs);
      final second = buildMatchRound([0, 1, 2], 42, colorPairs);

      expect(first.leftItems.length, 3);
      expect(first.rightItems.length, 3);
      expect(
        first.leftItems.map((item) => item.id).toList(),
        second.leftItems.map((item) => item.id).toList(),
      );
      expect(
        first.rightItems.map((item) => item.id).toList(),
        second.rightItems.map((item) => item.id).toList(),
      );
    });
  });

  group('connections', () {
    test('checks matching values', () {
      expect(isCorrectConnection(3, 3), isTrue);
      expect(isCorrectConnection(3, 4), isFalse);
    });

    test('detects completed round', () {
      final colorPairs = pickMatchColorPairs(3, createSeededRng(1));
      final round = buildMatchRound([0, 1, 2], 7, colorPairs);

      expect(
        isRoundComplete(
          round.values
              .map(
                (value) => MatchConnection(
                  leftId: 'left-$value',
                  rightId: 'right-$value',
                  value: value,
                ),
              )
              .toList(),
          3,
        ),
        isTrue,
      );
    });
  });

  group('parseFlashcardMatchParamsFromInput', () {
    test('reads pairCount, rounds and targetMode', () {
      expect(
        parseFlashcardMatchParamsFromInput(
          pairCount: 3,
          rounds: 2,
          targetMode: 'dots',
          totalRods: 2,
        ),
        {
          'pairCount': 3,
          'rounds': 2,
          'targetMode': 'dots',
          'totalRods': 2,
        },
      );
    });
  });
}
