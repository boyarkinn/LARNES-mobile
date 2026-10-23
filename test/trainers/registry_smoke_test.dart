import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/catalog/registry.dart';
import 'package:larnes_mobile/trainers/catalog/trainer_direction.dart';
import 'package:larnes_mobile/trainers/catalog/trainer_key.dart';

void main() {
  group('trainer registry', () {
    test('registers all 37 web trainer keys', () {
      expect(TrainerKey.values.length, 61);
      expect(trainerDefinitions.length, 61);
      expect(isTrainerKey('letter-find-tap'), isTrue);
      expect(isTrainerKey('example-visualization'), isTrue);
      expect(isTrainerKey('static-example-show'), isTrue);
      expect(isTrainerKey('topic-chain-flash'), isTrue);
      expect(isTrainerKey('topic-chain-table'), isTrue);
      expect(isTrainerKey('fly-track'), isTrue);
      expect(isTrainerKey('stroop-colors'), isTrue);
      expect(isTrainerKey('schulte-table'), isTrue);
      expect(isTrainerKey('wedge-tables'), isTrue);
      expect(isTrainerKey('reading-shutter'), isTrue);
      expect(isTrainerKey('reading-vanish'), isTrue);
      expect(isTrainerKey('reading-upside-down'), isTrue);
      expect(isTrainerKey('reading-pace-track'), isTrue);
      expect(isTrainerKey('reading-noisy-text'), isTrue);
      expect(isTrainerKey('reading-pointer'), isTrue);
      expect(isTrainerKey('reading-blocks'), isTrue);
      expect(isTrainerKey('reading-tree'), isTrue);
      expect(isTrainerKey('reading-flash'), isTrue);
      expect(isTrainerKey('reading-fixation'), isTrue);
      expect(isTrainerKey('reading-diagonal'), isTrue);
      expect(isTrainerKey('reading-reread'), isTrue);
      expect(isTrainerKey('reading-echo'), isTrue);
      expect(isTrainerKey('reading-phrases'), isTrue);
      expect(isTrainerKey('reading-find-span'), isTrue);
      expect(isTrainerKey('reading-word-sprint'), isTrue);
      expect(isTrainerKey('reading-cloze'), isTrue);
      expect(isTrainerKey('reading-story-order'), isTrue);
      expect(isTrainerKey('reading-main-idea'), isTrue);
      expect(isTrainerKey('reading-anagram'), isTrue);
      expect(isTrainerKey('reading-word-maze'), isTrue);
      expect(isTrainerKey('reading-grid-mask'), isTrue);
      expect(isTrainerKey('reading-snake'), isTrue);
      expect(isTrainerKey('reading-line-pace'), isTrue);
      expect(isTrainerKey('missing-trainer'), isFalse);
    });

    test('has native builder for every registered trainer', () {
      expect(trainerBuilders.length, 61);

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

      expect(readingDefinitions.length, 20);
      for (final definition in readingDefinitions) {
        expect(definition.isInteractive, isTrue, reason: definition.key.apiValue);
      }
    });

    test('speed-reading trainers keep the web interactive flags', () {
      final definitions = trainerDefinitions.values
          .where((definition) => definition.direction == TrainerDirection.speedReading);

      expect(definitions.length, 26);
      for (final definition in definitions) {
        expect(
          definition.isInteractive,
          definition.key != TrainerKey.readingBlocks &&
              definition.key != TrainerKey.readingTree &&
              definition.key != TrainerKey.readingDiagonal &&
              definition.key != TrainerKey.readingEcho,
          reason: definition.key.apiValue,
        );
      }
    });

    test('interactive flags match web for math and mental', () {
      expect(getTrainerDefinition('digit-find-tap')?.isInteractive, isTrue);
      expect(getTrainerDefinition('apple-count-show')?.isInteractive, isTrue);
      expect(getTrainerDefinition('number-row-show')?.isInteractive, isTrue);
      expect(getTrainerDefinition('flash-cards')?.isInteractive, isTrue);
      expect(getTrainerDefinition('example-visualization')?.isInteractive, isTrue);
      expect(getTrainerDefinition('static-example-show')?.isInteractive, isFalse);
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
