import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/reading/letter_model.dart';
import 'package:larnes_mobile/trainers/reading/letter_place_in_word/place_in_word_model.dart';
import 'package:larnes_mobile/trainers/reading/letter_place_in_word/place_in_word_sizes.dart';
import 'package:larnes_mobile/trainers/reading/reading_word_catalogs.dart';
import 'package:larnes_mobile/trainers/shared/seeded_rng.dart';

void main() {
  group('parsePracticeLetters', () {
    test('parses comma-separated letters in order', () {
      expect(parsePracticeLetters('Д, А, М'), ['Д', 'А', 'М']);
      expect(parsePracticeLetters('д а м'), ['Д', 'А', 'М']);
    });
  });

  group('resolveOmitForWord', () {
    test('uses practice letter priority', () {
      expect(
        resolveOmitForWord('Мама', ['А', 'М']),
        const OmitResolution(omitIndex: 1, omitLetter: 'А'),
      );
      expect(
        resolveOmitForWord('Мама', ['М', 'А']),
        const OmitResolution(omitIndex: 0, omitLetter: 'М'),
      );
    });

    test('omits first matching letter in word', () {
      expect(
        resolveOmitForWord('Дверь', ['Д', 'А', 'М']),
        const OmitResolution(omitIndex: 0, omitLetter: 'Д'),
      );
      expect(
        resolveOmitForWord('Арбуз', ['А', 'Р']),
        const OmitResolution(omitIndex: 0, omitLetter: 'А'),
      );
    });
  });

  group('countEligibleWords', () {
    test('counts words that contain practice letters', () {
      expect(countEligibleWords(['Д', 'А', 'М']), greaterThanOrEqualTo(5));
      expect(countEligibleWords([]), 0);
    });
  });

  group('pickWordsForRound', () {
    test('returns deterministic slugs for seed', () {
      final first = pickWordsForRound(
        entityCount: 2,
        practiceLetters: ['Д', 'А', 'М'],
        rng: createSeededRng(42),
      );
      final second = pickWordsForRound(
        entityCount: 2,
        practiceLetters: ['Д', 'А', 'М'],
        rng: createSeededRng(42),
      );

      expect(first, second);
      expect(first.length, 2);
    });
  });

  group('buildFillGapTask', () {
    test('splits word into before/after gap', () {
      final task = buildFillGapTask('watermelon', ['А'], 'lower', 'lower');

      expect(task.before, '');
      expect(task.after, 'рбуз');
      expect(task.correctLetter, 'а');
    });
  });

  group('buildFillGapTasks', () {
    test('builds tasks for round', () {
      final tasks = buildFillGapTasks(
        entityCount: 2,
        letterCase: 'upper',
        practiceLetters: ['Д', 'А', 'М'],
        seed: 7,
        wordCase: 'upper',
      );

      expect(tasks.length, 2);
    });
  });

  group('getFillGapWordImageSrc', () {
    test('returns null until assets are wired', () {
      expect(getFillGapWordImageSrc('door'), isNull);
      expect(getFillGapWordImageSrc('duck'), isNull);
    });
  });

  group('buildLetterPoolTiles', () {
    test('includes one tile per gap plus distractors', () {
      final tasks = buildFillGapTasks(
        entityCount: 2,
        letterCase: 'upper',
        practiceLetters: ['Д', 'А'],
        seed: 3,
        wordCase: 'upper',
      );
      final pool = buildLetterPoolTiles(
        distractorCount: 2,
        letterCase: 'upper',
        rng: createSeededRng(9),
        tasks: tasks,
      );

      expect(pool.length, 4);
    });
  });

  group('canFitLetterPool', () {
    test('limits pool size', () {
      expect(canFitLetterPool(3, 3), isTrue);
      expect(canFitLetterPool(8, 8), isFalse);
    });
  });

  group('place in word sizing', () {
    test('uses complete and wrong feedback delays from web scene', () {
      expect(fillGapCompleteDelayMs, 900);
      expect(fillGapWrongFeedbackMs, 550);
      expect(fillGapDragClickThresholdPx, 8);
    });
  });
}
