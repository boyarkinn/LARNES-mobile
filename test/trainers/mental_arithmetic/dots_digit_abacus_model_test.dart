import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/dots_digit_abacus/dots_digit_abacus_model.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/dots_digit_abacus/dots_digit_abacus_sizes.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_model.dart';
import 'package:larnes_mobile/trainers/shared/dot_layout.dart';

void main() {
  group('normalizeDotsDigitAbacusValue', () {
    test('clamps to 0..9', () {
      expect(normalizeDotsDigitAbacusValue(12), 9);
      expect(normalizeDotsDigitAbacusValue(-1), 0);
      expect(normalizeDotsDigitAbacusValue('7'), 7);
    });
  });

  group('getMaxValueForRods', () {
    test('returns 9 for one rod', () {
      expect(getMaxValueForRods(1), 9);
    });

    test('returns 99 for two rods', () {
      expect(getMaxValueForRods(2), 99);
    });
  });

  group('getTripleRepresentation', () {
    test('maps value 2 to two dots and one rod with digit 2', () {
      final result = getTripleRepresentation(2, kDotsDigitAbacusTotalRods);

      expect(result.dotCount, 2);
      expect(result.value, 2);
      expect(beadsToDigit(result.rods[0]), 2);
    });

    test('maps value 9 on one rod', () {
      final result = getTripleRepresentation(9, kDotsDigitAbacusTotalRods);

      expect(result.dotCount, 9);
      expect(beadsToDigit(result.rods[0]), 9);
    });
  });

  group('getExplainDotCountStart', () {
    test('starts at zero only for target 0', () {
      expect(getExplainDotCountStart(0), 0);
      expect(getExplainDotCountStart(1), 1);
      expect(getExplainDotCountStart(7), 1);
    });
  });

  group('getGridDotPositions', () {
    test('returns one position per dot for grid layout', () {
      expect(getGridDotPositions(9).length, 9);
    });
  });
}
