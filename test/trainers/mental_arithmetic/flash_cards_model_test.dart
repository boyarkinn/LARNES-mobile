import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/flash_cards/flash_cards_model.dart';

void main() {
  group('flash-cards model', () {
    test('parses comma-separated values', () {
      expect(parseFlashCardValues('3, 7,15'), [3, 7, 15]);
      expect(formatFlashCardValues([3, 7, 15]), '3,7,15');
    });

    test('validates values against totalRods', () {
      expect(isValidFlashCardValues('3,7', 1), isTrue);
      expect(isValidFlashCardValues('12', 1), isFalse);
    });

    test('normalizes legacy single value', () {
      expect(normalizeFlashCardValuesInput(7, 2), '7');
      expect(normalizeFlashCardValuesInput('3,5', 2), '3,5');
    });

    test('builds params from homework input', () {
      expect(
        parseFlashCardParamsFromInput(totalRods: 2, values: '3, 12'),
        {'totalRods': 2, 'values': '3,12'},
      );
    });

    test('keeps all comma-separated rounds', () {
      expect(
        parseFlashCardParamsFromInput(totalRods: 2, values: '10, 5, 14, 2'),
        {'totalRods': 2, 'values': '10,5,14,2'},
      );
    });
  });
}
