import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/catalog/registry.dart';
import 'package:larnes_mobile/trainers/catalog/trainer_direction.dart';
import 'package:larnes_mobile/trainers/catalog/trainer_key.dart';

void main() {
  group('trainer registry', () {
    test('registers all 37 web trainer keys', () {
      expect(TrainerKey.values.length, 37);
      expect(trainerDefinitions.length, 37);
      expect(isTrainerKey('letter-find-tap'), isTrue);
      expect(isTrainerKey('example-visualization'), isTrue);
      expect(isTrainerKey('static-example-show'), isTrue);
      expect(isTrainerKey('topic-chain-flash'), isTrue);
      expect(isTrainerKey('topic-chain-table'), isTrue);
      expect(isTrainerKey('fly-track'), isTrue);
      expect(isTrainerKey('stroop-colors'), isTrue);
      expect(isTrainerKey('schulte-table'), isTrue);
      expect(isTrainerKey('wedge-tables'), isTrue);
      expect(isTrainerKey('missing-trainer'), isFalse);
    });

    test('has native builder for every registered trainer', () {
      expect(trainerBuilders.length, 37);

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

      expect(readingDefinitions.length, 22);
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
      expect(getTrainerDefinition('topic-chain-flash')?.isInteractive, isTrue);
      expect(getTrainerDefinition('topic-chain-table')?.isInteractive, isFalse);
    });

    test('fly-track is intel and interactive in catalog', () {
      final definition = getTrainerDefinition('fly-track');

      expect(definition?.title, 'Муха');
      expect(definition?.direction, TrainerDirection.intel);
      expect(definition?.isInteractive, isTrue);
      expect(hasTrainerBuilder('fly-track'), isTrue);
    });
  });
}
