import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/reading/letter_find_tap/letter_find_tap_layout.dart';
import 'package:larnes_mobile/trainers/reading/letter_find_tap/letter_find_tap_model.dart';
import 'package:larnes_mobile/trainers/reading/letter_model.dart';
import 'package:larnes_mobile/trainers/shared/seeded_rng.dart';

void main() {
  group('normalizeTargetLetter', () {
    test('normalizes cyrillic letters without yo', () {
      expect(normalizeTargetLetter('а'), 'А');
      expect(normalizeTargetLetter('  м '), 'М');
      expect(isRussianLetterWithoutYo('ё'), isFalse);
    });
  });

  group('applyLetterCase', () {
    test('applies upper and lower case', () {
      expect(applyLetterCase('А', 'upper'), 'А');
      expect(applyLetterCase('А', 'lower'), 'а');
    });
  });

  group('canFitLetterField', () {
    test('accepts valid counts', () {
      expect(canFitLetterField(3, 12), isTrue);
    });

    test('rejects overflow', () {
      expect(canFitLetterField(9, 20), isFalse);
    });
  });

  group('buildLetterTokens', () {
    test('creates the requested number of targets and distractors', () {
      final rng = createSeededRng(42);
      final tokens = buildLetterTokens(
        BuildLetterFieldInput(
          distractorCount: 8,
          letterCase: 'upper',
          rng: rng,
          targetCount: 3,
          targetLetter: 'А',
        ),
      );

      expect(tokens.length, 11);
      expect(tokens.where((token) => token.isTarget).length, 3);
      expect(tokens.where((token) => !token.isTarget).length, 8);
      expect(
        tokens.every((token) => token.isTarget || token.letter != 'А'),
        isTrue,
      );
    });

    test('uses lowercase when requested', () {
      final tokens = buildLetterTokens(
        BuildLetterFieldInput(
          distractorCount: 2,
          letterCase: 'lower',
          rng: createSeededRng(7),
          targetCount: 2,
          targetLetter: 'Б',
        ),
      );

      expect(
        tokens.every((token) => token.letter == token.letter.toLowerCase()),
        isTrue,
      );
      expect(
        tokens
            .where((token) => token.isTarget)
            .every((token) => token.letter == 'б'),
        isTrue,
      );
    });

    test('is deterministic for the same seed', () {
      List<List<Object>> serialize(List<LetterToken> tokens) {
        return tokens
            .map((token) => [token.id, token.letter, token.isTarget])
            .toList();
      }

      final first = buildLetterTokens(
        BuildLetterFieldInput(
          distractorCount: 5,
          letterCase: 'upper',
          rng: createSeededRng(99),
          targetCount: 2,
          targetLetter: 'К',
        ),
      );
      final second = buildLetterTokens(
        BuildLetterFieldInput(
          distractorCount: 5,
          letterCase: 'upper',
          rng: createSeededRng(99),
          targetCount: 2,
          targetLetter: 'К',
        ),
      );

      expect(serialize(first), equals(serialize(second)));
    });
  });

  group('allTargetsFound', () {
    test('returns true only when every target id is found', () {
      final tokens = buildLetterTokens(
        BuildLetterFieldInput(
          distractorCount: 2,
          letterCase: 'upper',
          rng: createSeededRng(1),
          targetCount: 2,
          targetLetter: 'Р',
        ),
      );
      final targetIds =
          tokens.where((token) => token.isTarget).map((token) => token.id).toList();

      expect(allTargetsFound({targetIds[0]}, tokens), isFalse);
      expect(allTargetsFound(targetIds.toSet(), tokens), isTrue);
    });
  });

  group('layout salt', () {
    test('changes letter placement when salt differs', () {
      const base = (
        distractorCount: 8,
        letterCase: 'upper',
        targetCount: 3,
        targetLetter: 'А',
      );

      List<List<double>> placeWithSalt(int layoutSalt) {
        final seed = hashParamsSeed([
          base.targetLetter,
          base.letterCase,
          base.targetCount,
          base.distractorCount,
          layoutSalt,
        ]);
        final rng = createSeededRng(seed);
        final tokens = buildLetterTokens(
          BuildLetterFieldInput(
            distractorCount: base.distractorCount,
            letterCase: base.letterCase,
            rng: rng,
            targetCount: base.targetCount,
            targetLetter: base.targetLetter,
          ),
        );

        return placeLetterTokens(tokens, rng)
            .map((letter) => [letter.xPercent, letter.yPercent])
            .toList();
      }

      expect(placeWithSalt(11), isNot(equals(placeWithSalt(22))));
    });
  });
}
