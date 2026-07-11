import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/reading/letter_word_link/word_link_model.dart';
import 'package:larnes_mobile/trainers/reading/letter_word_link/word_link_reveal.dart';
import 'package:larnes_mobile/trainers/reading/letter_word_link/word_link_size.dart';
import 'package:larnes_mobile/trainers/reading/reading_word_catalogs.dart';
import 'package:larnes_mobile/trainers/shared/seeded_rng.dart';

void main() {
  group('canBuildWordLinkRound', () {
    test('allows a typical round for letter A', () {
      expect(canBuildWordLinkRound('А', 4), isTrue);
    });

    test('rejects too many cards when distractors are unavailable', () {
      expect(canBuildWordLinkRound('Ъ', 8), isFalse);
    });
  });

  group('buildWordLinkRound', () {
    test('includes matching and non-matching words', () {
      const input = BuildWordLinkRoundInput(
        entityCount: 4,
        letter: 'А',
        letterCase: 'upper',
        seed: 7,
        wordCase: 'upper',
      );
      final round = buildWordLinkRound(input);
      final matches = round.wordItems.where((item) => item.isMatch).toList();
      final distractors =
          round.wordItems.where((item) => !item.isMatch).toList();

      expect(round.wordItems.length, 4);
      expect(
        matches.length,
        countCorrectWordLinkItems(4, getWordsByFirstLetter('А').length),
      );
      expect(matches.length >= minWordLinkCorrectItems, isTrue);
      expect(distractors.length >= 1, isTrue);
      expect(
        matches.every((item) => getWordLinkFirstLetter(item.slug) == 'А'),
        isTrue,
      );
      expect(
        distractors.every((item) => getWordLinkFirstLetter(item.slug) != 'А'),
        isTrue,
      );
    });

    test('is deterministic for the same seed', () {
      const input = BuildWordLinkRoundInput(
        entityCount: 4,
        letter: 'А',
        letterCase: 'upper',
        seed: 11,
        wordCase: 'upper',
      );
      final first = buildWordLinkRound(input);
      final second = buildWordLinkRound(input);

      expect(first.displayLetter, second.displayLetter);
      expect(first.letter, second.letter);
      expect(
        first.wordItems.map(
          (item) => [item.id, item.slug, item.isMatch, item.displayLabel],
        ),
        second.wordItems.map(
          (item) => [item.id, item.slug, item.isMatch, item.displayLabel],
        ),
      );
    });
  });

  group('isWordLinkRoundComplete', () {
    test('completes only after all matching words are connected', () {
      const input = BuildWordLinkRoundInput(
        entityCount: 4,
        letter: 'А',
        letterCase: 'upper',
        seed: 3,
        wordCase: 'upper',
      );
      final round = buildWordLinkRound(input);
      final matches = round.wordItems.where((item) => item.isMatch).toList();

      expect(isWordLinkRoundComplete([], round), isFalse);
      expect(
        isWordLinkRoundComplete(
          [
            WordLinkConnection(
              rightId: matches.first.id,
              slug: matches.first.slug,
            ),
          ],
          round,
        ),
        matches.length == 1,
      );
      expect(
        isWordLinkRoundComplete(
          [
            for (final item in matches)
              WordLinkConnection(rightId: item.id, slug: item.slug),
          ],
          round,
        ),
        isTrue,
      );
    });
  });

  group('buildWordLinkRoundSeed', () {
    test('changes with params', () {
      expect(
        buildWordLinkRoundSeed(['А', 4, 'upper', 'upper']),
        isNot(buildWordLinkRoundSeed(['М', 4, 'upper', 'upper'])),
      );
    });

    test('includes word-link trainer key in hash', () {
      final withKey = buildWordLinkRoundSeed(['А', 4, 'upper', 'upper']);
      final withoutKey = hashParamsSeed(['А', 4, 'upper', 'upper']);

      expect(withKey, isNot(withoutKey));
    });
  });

  group('word link sizing', () {
    test('caps letter box by height and width fractions', () {
      expect(getWordLinkLetterBoxSize(800, 400), 88);
      expect(getWordLinkLetterFontSize(88), 63);
    });

    test('caps card min height', () {
      expect(getWordLinkCardMinHeight(800), 72);
      expect(getWordLinkCardMinHeight(400), 48);
    });
  });

  group('word link reveal', () {
    test('staggers cards after letter pop', () {
      expect(getWordLinkCardRevealDelayMs(0, 4), greaterThan(0));
      expect(
        getWordLinkInteractionReadyMs(4),
        greaterThan(getWordLinkCardRevealDelayMs(3, 4)),
      );
    });
  });
}
