import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/flash_cards/flash_cards_model.dart';

void main() {
  group('flash-cards model', () {
    test('parses comma-separated values', () {
      expect(parseFlashCardValues('3, 7,15'), [3, 7, 15]);
      expect(formatFlashCardValues([3, 7, 15]), '3,7,15');
    });

    test('clamps card count', () {
      expect(clampFlashCardCount(0), 1);
      expect(clampFlashCardCount(5), 5);
      expect(clampFlashCardCount(99), 10);
    });

    test('builds params from topic and card count', () {
      expect(
        parseFlashCardParamsFromInput(
          chainTopicId: 'simple-2digit',
          rounds: 5,
        ),
        {
          'topicId': 'simple-2digit',
          'cardCount': 5,
        },
      );
    });

    test('keeps legacy values for playback', () {
      expect(
        parseFlashCardParamsFromInput(
          chainTopicId: 'simple-2digit',
          values: '3, 12',
        ),
        {
          'topicId': 'simple-2digit',
          'cardCount': 2,
          'values': '3,12',
        },
      );
    });

    test('generates deterministic cards from topic seed', () {
      final seed = buildFlashCardSessionSeed(
        cardCount: 4,
        topicId: 'brother-3-1digit',
      );
      final first = buildFlashCardSessionValues(
        cardCount: 4,
        topicId: 'brother-3-1digit',
        masterSeed: seed,
      );
      final second = buildFlashCardSessionValues(
        cardCount: 4,
        topicId: 'brother-3-1digit',
        masterSeed: seed,
      );

      expect(first, second);
      expect(first, hasLength(4));
      expect(first.toSet(), hasLength(4));
    });

    test('builds four nearby unique answers of the same digit count', () {
      final options = buildFlashCardAnswerOptions(42, random: math.Random(17));

      expect(options, hasLength(4));
      expect(options.toSet(), hasLength(4));
      expect(options, contains(42));
      expect(options.every((value) => value >= 10 && value <= 99), isTrue);
      expect(
        options
            .where((value) => value != 42)
            .every((value) => (value - 42).abs() <= 8),
        isTrue,
      );
    });
  });
}
