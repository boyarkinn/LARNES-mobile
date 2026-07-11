import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/reading/letter_first_by_image/first_by_image_model.dart';
import 'package:larnes_mobile/trainers/reading/letter_model.dart';
import 'package:larnes_mobile/trainers/reading/reading_word_catalogs.dart';
import 'package:larnes_mobile/trainers/shared/seeded_rng.dart';

void main() {
  group('word catalog helpers', () {
    test('derives first letter from slug', () {
      expect(getFirstLetterFromWordSlug('stork'), 'А');
      expect(getFirstLetterFromWordSlug('cat'), 'К');
    });

    test('applies word case', () {
      expect(applyWordCase('Аист', 'lower'), 'аист');
    });

    test('returns null image src until assets are wired', () {
      expect(getFirstByImageWordImageSrc('stork'), isNull);
      expect(getFirstByImageWordImageSrc('cat'), isNull);
    });
  });

  group('buildLetterChoices', () {
    test('includes the target letter once', () {
      final choices = buildLetterChoices(
        BuildLetterChoicesInput(
          distractorCount: 3,
          firstLetter: 'А',
          letterCase: 'upper',
          rng: createSeededRng(5),
          wordSlug: 'stork',
        ),
      );

      expect(choices.length, 4);
      expect(choices.where((letter) => letter == 'А').length, 1);
    });
  });

  group('canFitLetterChoices', () {
    test('limits button count', () {
      expect(canFitLetterChoices(3), isTrue);
      expect(canFitLetterChoices(8), isFalse);
    });
  });

  group('isCorrectLetterChoice', () {
    test('matches case-aware target', () {
      expect(isCorrectLetterChoice('А', 'lower', 'а'), isTrue);
      expect(isCorrectLetterChoice('А', 'upper', 'а'), isFalse);
    });
  });

  group('getWordAudioStubMessage', () {
    test('includes the word', () {
      expect(getWordAudioStubMessage('Аист'), contains('«Аист»'));
    });
  });

  group('buildFirstByImageChoicesSeed', () {
    test('includes first-by-image trainer key in hash', () {
      final withKey = buildFirstByImageChoicesSeed(
        wordSlug: 'stork',
        wordCase: 'upper',
        letterCase: 'upper',
        distractorCount: 3,
        layoutSalt: 99,
      );
      final withoutKey = hashParamsSeed([
        'stork',
        'upper',
        'upper',
        3,
        99,
      ]);

      expect(withKey, isNot(withoutKey));
      expect(
        buildFirstByImageChoicesSeed(
          wordSlug: 'stork',
          wordCase: 'upper',
          letterCase: 'upper',
          distractorCount: 3,
          layoutSalt: 99,
        ),
        withKey,
      );
    });
  });
}
