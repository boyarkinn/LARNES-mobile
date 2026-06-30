import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/math/number_composition/number_composition_model.dart';

void main() {
  group('getCompositionEquation', () {
    test('builds equation for 1 + 1 = 2', () {
      expect(
        getCompositionEquation(2, 1),
        const CompositionEquation(knownPart: 1, missingPart: 1, whole: 2),
      );
    });
  });

  group('getMissingPart', () {
    test('subtracts known part from whole', () {
      expect(getMissingPart(5, 2), 3);
    });
  });

  group('answer range checks', () {
    test('validates digit button range', () {
      expect(isMissingPartInDigitRange(1, 0), isTrue);
      expect(isMissingPartInDigitRange(4, 0), isFalse);
    });

    test('validates dot choice range', () {
      expect(isMissingPartInDotRange(3), isTrue);
      expect(isMissingPartInDotRange(4), isFalse);
    });
  });

  group('getDigitAnswerChoices', () {
    test('returns four consecutive values', () {
      expect(getDigitAnswerChoices(2), [2, 3, 4, 5]);
    });
  });

  group('getNextPhase', () {
    test('walks through phases', () {
      expect(getNextPhase('demo-dots'), 'demo-digits');
      expect(getNextPhase('practice-digits'), isNull);
    });
  });

  group('isValidComposition', () {
    test('accepts valid params', () {
      expect(isValidComposition(2, 1), isTrue);
    });

    test('rejects known part equal to whole', () {
      expect(isValidComposition(2, 2), isFalse);
    });
  });
}
