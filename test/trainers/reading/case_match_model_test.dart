import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/reading/letter_case_match/case_match_model.dart';
import 'package:larnes_mobile/trainers/shared/seeded_rng.dart';

void main() {
  group('parseCaseMatchPracticeLetters', () {
    test('reuses shared parser', () {
      expect(parseCaseMatchPracticeLetters('А, м, к'), ['А', 'М', 'К']);
    });
  });

  group('canUsePairCount', () {
    test('checks pair count against available letters', () {
      const letters = ['А', 'М', 'К'];

      expect(canUsePairCount(letters, 2), isTrue);
      expect(canUsePairCount(letters, 4), isFalse);
      expect(canUsePairCount(letters, 1), isFalse);
    });
  });

  group('pickLettersForRound', () {
    test('returns deterministic subset', () {
      const letters = ['А', 'М', 'К', 'О', 'У'];
      final first = pickLettersForRound(
        pairCount: 3,
        practiceLetters: letters,
        rng: createSeededRng(11),
      );
      final second = pickLettersForRound(
        pairCount: 3,
        practiceLetters: letters,
        rng: createSeededRng(11),
      );

      expect(first, second);
      expect(first.length, 3);
    });
  });

  group('buildLetterMatchRound', () {
    test('creates lowercase and uppercase sides', () {
      final round = buildLetterMatchRound(['А', 'М'], 5);

      expect(round.leftItems.length, 2);
      expect(round.rightItems.length, 2);
      expect(round.leftItems.any((item) => item.displayLetter == 'а'), isTrue);
      expect(round.rightItems.any((item) => item.displayLetter == 'А'), isTrue);
    });
  });

  group('isCorrectLetterMatch', () {
    test('matches same normalized letter', () {
      expect(isCorrectLetterMatch('А', 'А'), isTrue);
      expect(isCorrectLetterMatch('А', 'М'), isFalse);
    });
  });

  group('isCaseMatchRoundComplete', () {
    test('requires all letters connected', () {
      expect(
        isCaseMatchRoundComplete(
          const [
            LetterMatchConnection(
              leftId: 'left-А',
              letter: 'А',
              rightId: 'right-А',
            ),
            LetterMatchConnection(
              leftId: 'left-М',
              letter: 'М',
              rightId: 'right-М',
            ),
          ],
          ['А', 'М'],
        ),
        isTrue,
      );
      expect(
        isCaseMatchRoundComplete(
          const [
            LetterMatchConnection(
              leftId: 'left-А',
              letter: 'А',
              rightId: 'right-А',
            ),
          ],
          ['А', 'М'],
        ),
        isFalse,
      );
    });
  });

  group('buildSelectedLetters', () {
    test('builds selected letters for round', () {
      final selected = buildSelectedLetters(
        pairCount: 2,
        practiceLetters: ['А', 'М', 'К'],
        seed: 3,
      );

      expect(selected.length, 2);
    });
  });

  group('buildCaseMatchRoundSeed', () {
    test('includes case-match trainer key in hash', () {
      expect(
        buildCaseMatchRoundSeed(['3', 'А,М']),
        buildCaseMatchRoundSeed(['3', 'А,М']),
      );
      expect(
        buildCaseMatchRoundSeed(['3', 'А,М']),
        isNot(buildCaseMatchRoundSeed(['4', 'А,М'])),
      );
    });
  });
}
