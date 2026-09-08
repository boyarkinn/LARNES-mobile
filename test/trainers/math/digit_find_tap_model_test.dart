import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/math/digit_find_tap/digit_find_tap_model.dart';
import 'package:larnes_mobile/trainers/shared/seeded_rng.dart';

void main() {
  group('normalizeTargetDigit', () {
    test('clamps to 0-9', () {
      expect(normalizeTargetDigit(-3), 0);
      expect(normalizeTargetDigit(4.8), 4);
      expect(normalizeTargetDigit(12), 9);
    });
  });

  group('isValidDigitFindTapValues', () {
    test('accepts digits 0-9', () {
      expect(isValidDigitFindTapValues('0,2,5,9'), isTrue);
      expect(isValidDigitFindTapValues('7'), isTrue);
    });

    test('rejects out-of-range and garbage parts', () {
      expect(isValidDigitFindTapValues('2,12,7'), isFalse);
      expect(isValidDigitFindTapValues('2,-1'), isFalse);
      expect(isValidDigitFindTapValues('2,foo'), isFalse);
      expect(isValidDigitFindTapValues(''), isFalse);
    });
  });

  group('parseDigitFindTapValues', () {
    test('parses comma-separated digits', () {
      expect(parseDigitFindTapValues('2,5,7'), [2, 5, 7]);
    });
  });

  group('canFitDigitField', () {
    test('accepts valid counts', () {
      expect(canFitDigitField(12), isTrue);
    });

    test('rejects overflow', () {
      expect(canFitDigitField(28), isFalse);
    });
  });

  group('buildDigitTokens', () {
    test('creates one target and the requested distractors', () {
      final rng = createSeededRng(42);
      final tokens = buildDigitTokens(
        BuildDigitFieldInput(
          distractorCount: 8,
          rng: rng,
          targetDigit: 2,
        ),
      );

      expect(tokens.length, 9);
      expect(tokens.where((token) => token.isTarget).length, 1);
      expect(tokens.where((token) => !token.isTarget).length, 8);
      expect(
        tokens.every((token) => token.isTarget || token.digit != 2),
        isTrue,
      );
    });

    test('is deterministic for the same seed', () {
      List<List<Object>> serialize(List<DigitToken> tokens) {
        return tokens
            .map((token) => [token.id, token.digit, token.isTarget])
            .toList();
      }

      final first = buildDigitTokens(
        BuildDigitFieldInput(
          distractorCount: 5,
          rng: createSeededRng(99),
          targetDigit: 7,
        ),
      );
      final second = buildDigitTokens(
        BuildDigitFieldInput(
          distractorCount: 5,
          rng: createSeededRng(99),
          targetDigit: 7,
        ),
      );

      expect(serialize(first), equals(serialize(second)));
    });
  });

  group('allTargetsFound', () {
    test('returns true only when every target id is found', () {
      final tokens = buildDigitTokens(
        BuildDigitFieldInput(
          distractorCount: 2,
          rng: createSeededRng(1),
          targetDigit: 4,
        ),
      );
      final targetIds =
          tokens.where((token) => token.isTarget).map((token) => token.id).toList();

      expect(allTargetsFound({}, tokens), isFalse);
      expect(allTargetsFound(targetIds.toSet(), tokens), isTrue);
    });
  });
}
