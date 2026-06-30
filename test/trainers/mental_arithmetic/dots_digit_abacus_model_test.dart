import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/dots_digit_abacus/dots_digit_abacus_model.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_model.dart';
import 'package:larnes_mobile/trainers/shared/dot_layout.dart';

void main() {
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
      final result = getTripleRepresentation(2, 1);

      expect(result.dotCount, 2);
      expect(result.value, 2);
      expect(beadsToDigit(result.rods[0]), 2);
    });

    test('maps value 12 across two rods', () {
      final result = getTripleRepresentation(12, 2);

      expect(result.dotCount, 12);
      expect(beadsToDigit(result.rods[1]), 2);
      expect(beadsToDigit(result.rods[0]), 1);
    });
  });

  group('getGridDotPositions', () {
    test('returns one position per dot for grid layout', () {
      expect(getGridDotPositions(12).length, 12);
    });
  });
}
