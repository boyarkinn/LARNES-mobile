import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/catalog/registry.dart';
import 'package:larnes_mobile/trainers/catalog/trainer_direction.dart';
import 'package:larnes_mobile/trainers/catalog/trainer_key.dart';

void main() {
  group('trainer registry', () {
    test('registers all 29 web trainer keys', () {
      expect(TrainerKey.values.length, 29);
      expect(trainerDefinitions.length, 29);
      expect(isTrainerKey('letter-find-tap'), isTrue);
      expect(isTrainerKey('missing-trainer'), isFalse);
    });

    test('has 10 native builders and 19 reading stubs', () {
      expect(trainerBuilders.length, 10);
      expect(hasTrainerBuilder('number-row-show'), isTrue);
      expect(hasTrainerBuilder('letter-find-tap'), isFalse);

      final readingDefinitions = trainerDefinitions.values
          .where((definition) => definition.direction == TrainerDirection.reading);
      expect(readingDefinitions.length, 19);
      for (final definition in readingDefinitions) {
        expect(definition.isInteractive, isTrue);
        expect(hasTrainerBuilder(definition.key.apiValue), isFalse);
      }
    });

    test('interactive flags match web for math and mental', () {
      expect(getTrainerDefinition('digit-find-tap')?.isInteractive, isTrue);
      expect(getTrainerDefinition('number-row-show')?.isInteractive, isFalse);
      expect(getTrainerDefinition('abacus-show')?.isInteractive, isFalse);
      expect(getTrainerDefinition('flashcard-digit-match')?.isInteractive, isTrue);
    });
  });
}
