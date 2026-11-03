import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/reading/letter_model.dart';
import 'package:larnes_mobile/trainers/reading/letter_place_in_word/place_in_word_model.dart';
import 'package:larnes_mobile/trainers/reading/letter_place_in_word/place_in_word_sizes.dart';
import 'package:larnes_mobile/trainers/reading/reading_word_catalogs.dart';
import 'package:larnes_mobile/trainers/shared/seeded_rng.dart';
import 'package:larnes_mobile/trainers/shared/first_words/catalog.dart';

void main() {
  group('short word selection', () {
    test('keeps four-letter words without changing the shared catalog', () {
      for (final slug in ['1_аист', '7_ёжик', '15_гусь', '31_щука']) {
        expect(fillGapWordSlugs, contains(slug));
      }
      for (final slug in [
        '1_арбуз', '17_дверь', '1_автобус', '21_замок1', '21_замок2',
      ]) {
        expect(fillGapWordSlugs, isNot(contains(slug)));
        expect(firstWords.any((word) => word.slug == slug), isTrue);
      }
    });

    test('generates only short words across repeated rounds', () {
      for (var seed = 0; seed < 20; seed++) {
        final slugs = pickWordsForRound(
          entityCount: 6,
          practiceLetters: ['А', 'О', 'И', 'Е', 'У', 'Ы', 'Я', 'Ю', 'Ё', 'Э'],
          rng: createSeededRng(seed),
        );
        expect(slugs.length, 6);
        expect(slugs.toSet().length, 6);
        expect(
          slugs.every((slug) => getFillGapWordLabel(slug).length <= 4),
          isTrue,
        );
      }
    });

    test('counts only the remaining words for the selected letters', () {
      expect(countEligibleWords(['Э']), 1);
      expect(
        pickWordsForRound(
          entityCount: 2,
          practiceLetters: ['Э'],
          rng: createSeededRng(1),
        ),
        isEmpty,
      );
    });
  });

  group('parsePracticeLetters', () {
    test('parses comma-separated letters in order', () {
      expect(parsePracticeLetters('Д, А, М'), ['Д', 'А', 'М']);
      expect(parsePracticeLetters('д а м'), ['Д', 'А', 'М']);
    });

    test('supports Ё for fill-gap words', () {
      expect(parseFillGapPracticeLetters('ё, е'), ['Ё', 'Е']);
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
      final task = buildFillGapTask('1_арбуз', ['А'], 'lower', 'lower');

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
    test('resolves shared first-words assets', () {
      expect(
        getFillGapWordImageSrc('17_дверь'),
        'assets/images/ru/first-words/17-Д/17_дверь.png',
      );
      expect(
        getFillGapWordImageSrc('3_утка'),
        'assets/images/ru/first-words/3-У/3_утка.png',
      );
    });

    test('removes technical image variant suffixes', () {
      expect(normalizeFillGapWordLabel('замок1'), 'замок');
      expect(normalizeFillGapWordLabel('замок2'), 'замок');
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
