import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/reading/letter_model.dart';
import 'package:larnes_mobile/trainers/reading/letter_odd_one_out/odd_one_out_model.dart';
import 'package:larnes_mobile/trainers/shared/seeded_rng.dart';

void main() {
  group('resolveOddLetter', () {
    test('returns the requested odd letter when it differs from main', () {
      expect(resolveOddLetter('А', 'Л', createSeededRng(1)), 'Л');
    });

    test('picks a different letter when random or same as main', () {
      final randomOdd = resolveOddLetter('А', 'random', createSeededRng(42));
      expect(randomOdd, isNot('А'));

      final sameAsMain = resolveOddLetter('А', 'А', createSeededRng(7));
      expect(sameAsMain, isNot('А'));
    });
  });

  group('isValidOddLetterParam', () {
    test('accepts random and different letters', () {
      expect(isValidOddLetterParam('А', 'random'), isTrue);
      expect(isValidOddLetterParam('А', 'Л'), isTrue);
    });

    test('rejects the same letter', () {
      expect(isValidOddLetterParam('А', 'А'), isFalse);
    });
  });

  group('buildOddOneOutTokens', () {
    test('creates one odd target and the rest as main letters', () {
      final tokens = buildOddOneOutTokens(
        BuildOddOneOutInput(
          letter: 'А',
          letterCase: 'upper',
          letterCount: 10,
          oddLetter: 'Л',
          rng: createSeededRng(11),
        ),
      );

      expect(tokens.length, 10);
      expect(tokens.where((token) => token.isTarget).length, 1);
      expect(tokens.where((token) => !token.isTarget).length, 9);
      expect(
        tokens.every((token) => token.isTarget || token.letter == 'А'),
        isTrue,
      );
      expect(tokens.firstWhere((token) => token.isTarget).letter, 'Л');
    });

    test('is deterministic for the same seed', () {
      final first = buildOddOneOutTokens(
        BuildOddOneOutInput(
          letter: 'М',
          letterCase: 'lower',
          letterCount: 8,
          oddLetter: 'random',
          rng: createSeededRng(99),
        ),
      );
      final second = buildOddOneOutTokens(
        BuildOddOneOutInput(
          letter: 'М',
          letterCase: 'lower',
          letterCount: 8,
          oddLetter: 'random',
          rng: createSeededRng(99),
        ),
      );

      expect(
        first.map((token) => [token.id, token.letter, token.isTarget]),
        second.map((token) => [token.id, token.letter, token.isTarget]),
      );
    });
  });

  group('isOddLetterFound', () {
    test('returns true only when the odd token is found', () {
      final tokens = buildOddOneOutTokens(
        BuildOddOneOutInput(
          letter: 'К',
          letterCase: 'upper',
          letterCount: 6,
          oddLetter: 'П',
          rng: createSeededRng(3),
        ),
      );
      final oddId = tokens.firstWhere((token) => token.isTarget).id;
      final mainId = tokens.firstWhere((token) => !token.isTarget).id;

      expect(isOddLetterFound({mainId}, tokens), isFalse);
      expect(isOddLetterFound({oddId}, tokens), isTrue);
    });
  });

  group('buildOddOneOutRoundSeed', () {
    test('includes letter-odd-one-out trainer key in hash', () {
      final withKey = buildOddOneOutRoundSeed(['А', 'Л', 10, 'upper', 9]);
      final withoutKey = hashParamsSeed(['А', 'Л', 10, 'upper', 9]);

      expect(withKey, isNot(withoutKey));
    });
  });
}
