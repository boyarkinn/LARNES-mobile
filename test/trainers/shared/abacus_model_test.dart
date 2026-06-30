import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_model.dart';

void main() {
  group('digitToBeads / beadsToDigit', () {
    for (var digit = 0; digit <= 9; digit++) {
      test('round-trip for digit $digit', () {
        final state = digitToBeads(digit);
        expect(beadsToDigit(state), digit);
        expect(state.heavenUp, digit >= 5);
        expect(state.earthCount, digit >= 5 ? digit - 5 : digit);
      });
    }

    test('normalizes digit outside 0-9 via modulo', () {
      expect(digitToBeads(17), digitToBeads(7));
    });
  });

  group('numberToAbacus / abacusToNumber', () {
    test('uses MSB-left order', () {
      final rods = numberToAbacus(123, 5);

      expect(rods.length, 5);
      expect(beadsToDigit(rods[0]), 0);
      expect(beadsToDigit(rods[1]), 0);
      expect(beadsToDigit(rods[2]), 1);
      expect(beadsToDigit(rods[3]), 2);
      expect(beadsToDigit(rods[4]), 3);
    });

    test('round-trips multi-digit values', () {
      final rods = numberToAbacus(9876, 4);
      expect(abacusToNumber(rods), 9876);
    });

    test('pads with leading zero rods', () {
      final rods = numberToAbacus(7, 3);
      expect(abacusToNumber(rods), 7);
      expect(beadsToDigit(rods[0]), 0);
      expect(beadsToDigit(rods[1]), 0);
      expect(beadsToDigit(rods[2]), 7);
    });

    test('truncates overflow beyond totalRods', () {
      final rods = numberToAbacus(12345, 3);
      expect(abacusToNumber(rods), 345);
    });

    test('zero fills all rods', () {
      final rods = numberToAbacus(0, 4);
      expect(abacusToNumber(rods), 0);
      expect(
        rods.every((rod) => !rod.heavenUp && rod.earthCount == 0),
        isTrue,
      );
    });
  });
}
