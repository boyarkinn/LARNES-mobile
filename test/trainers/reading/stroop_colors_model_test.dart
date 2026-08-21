import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/reading/stroop_colors/model.dart';

double Function() sequenceRng(List<double> values) {
  var index = 0;
  return () {
    final value = index < values.length ? values[index] : 0.99;
    index += 1;
    return value;
  };
}

void main() {
  group('stroop-colors model', () {
    test('keeps the seven rainbow colors', () {
      expect(stroopColorIds.length, 7);
      expect(stroopColors.length, 7);
      expect(stroopColors['cyan']?.label, 'Голубой');
      expect(stroopColors['blue']?.label, 'Синий');
    });

    test('generates only incongruent items of the requested length', () {
      final items = generateStroopItems(
        GenerateStroopItemsInput(
          random: sequenceRng([0, 0.2, 0.4, 0.6, 0.8, 0.1, 0.9, 0.3]),
          wordCount: 8,
        ),
      );

      expect(items.length, 8);
      for (final item in items) {
        expect(item.ink, isNot(item.word));
        expect(stroopColorIds, contains(item.ink));
        expect(stroopColorIds, contains(item.word));
      }
    });

    test('avoids repeating the previous pair', () {
      final items = generateStroopItems(
        GenerateStroopItemsInput(
          random: () => 0,
          wordCount: 6,
        ),
      );

      for (var index = 1; index < items.length; index++) {
        final previous = items[index - 1];
        final current = items[index];
        expect(
          previous.ink == current.ink && previous.word == current.word,
          isFalse,
        );
      }
    });
  });
}
