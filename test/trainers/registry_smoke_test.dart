import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/catalog/registry.dart';
import 'package:larnes_mobile/trainers/catalog/trainer_direction.dart';
import 'package:larnes_mobile/trainers/catalog/trainer_key.dart';

void main() {
  group('trainer registry', () {
    test('registers all 31 web trainer keys', () {
      expect(TrainerKey.values.length, 31);
      expect(trainerDefinitions.length, 31);
      expect(isTrainerKey('letter-find-tap'), isTrue);
      expect(isTrainerKey('example-visualization'), isTrue);
      expect(isTrainerKey('static-example-show'), isTrue);
      expect(isTrainerKey('missing-trainer'), isFalse);
    });

    test('has native builder for every registered trainer', () {
      expect(trainerBuilders.length, 31);

      for (final key in TrainerKey.values) {
        expect(
          hasTrainerBuilder(key.apiValue),
          isTrue,
          reason: key.apiValue,
        );
      }
    });

    test('reading trainers are interactive', () {
      final readingDefinitions = trainerDefinitions.values
          .where((definition) => definition.direction == TrainerDirection.reading);

      expect(readingDefinitions.length, 19);
      for (final definition in readingDefinitions) {
        expect(definition.isInteractive, isTrue);
      }
    });

    test('interactive flags match web for math and mental', () {
      expect(getTrainerDefinition('digit-find-tap')?.isInteractive, isTrue);
      expect(getTrainerDefinition('number-row-show')?.isInteractive, isFalse);
      expect(getTrainerDefinition('abacus-show')?.isInteractive, isFalse);
      expect(getTrainerDefinition('example-visualization')?.isInteractive, isFalse);
      expect(getTrainerDefinition('static-example-show')?.isInteractive, isFalse);
      expect(getTrainerDefinition('flashcard-digit-match')?.isInteractive, isTrue);
    });
  });
}
