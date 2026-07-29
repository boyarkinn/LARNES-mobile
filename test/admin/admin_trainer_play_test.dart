import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/features/admin/models/trainer_play.dart';
import 'package:larnes_mobile/trainers/catalog/registry.dart';
import 'package:larnes_mobile/trainers/catalog/trainer_key.dart';

void main() {
  group('mobile play gate', () {
    test('all registered trainers have native builders', () {
      expect(trainerBuilders.length, 32);

      for (final key in TrainerKey.values) {
        expect(hasTrainerBuilder(key.apiValue), isTrue, reason: key.apiValue);
      }
    });

    test('dots-digit-abacus has native builder', () {
      expect(hasTrainerBuilder('dots-digit-abacus'), isTrue);
    });

    test('letter-find-tap has native builder', () {
      expect(isTrainerKey('letter-find-tap'), isTrue);
      expect(hasTrainerBuilder('letter-find-tap'), isTrue);
    });

    test('letter-trace has native builder', () {
      expect(isTrainerKey('letter-trace'), isTrue);
      expect(hasTrainerBuilder('letter-trace'), isTrue);
    });

    test('letter-color has native builder', () {
      expect(isTrainerKey('letter-color'), isTrue);
      expect(hasTrainerBuilder('letter-color'), isTrue);
    });

    test('letter-case-color has native builder', () {
      expect(isTrainerKey('letter-case-color'), isTrue);
      expect(hasTrainerBuilder('letter-case-color'), isTrue);
    });
  });

  group('AdminTrainerPlayLaunch', () {
    test('carries trainer params for native player', () {
      const launch = AdminTrainerPlayLaunch(
        trainerKey: 'dots-digit-abacus',
        title: 'Dots',
        params: {'digit': 3},
      );

      expect(launch.trainerKey, 'dots-digit-abacus');
      expect(launch.params['digit'], 3);
    });
  });

  group('TrainerPlayConfig.fromJson', () {
    test('parses play config with defaults and fields', () {
      final config = TrainerPlayConfig.fromJson({
        'status': 'success',
        'trainerKey': 'digit-find-tap',
        'title': 'Find digit',
        'direction': 'math',
        'isInteractive': true,
        'defaultParams': {
          'digit': 2,
          'targetCount': 3,
          'distractorCount': 12,
        },
        'fields': [
          {
            'key': 'digit',
            'type': 'number',
            'labelKey': 'digitLabel',
            'min': 0,
            'max': 9,
          },
        ],
      });

      expect(config.trainerKey, 'digit-find-tap');
      expect(config.isInteractive, isTrue);
      expect(config.initialValues()['digit'], '2');
      expect(config.fields, hasLength(1));
    });

    test('parses fractional min on number fields', () {
      final config = TrainerPlayConfig.fromJson({
        'status': 'success',
        'trainerKey': 'example-visualization',
        'title': 'Example visualization',
        'direction': 'mental',
        'isInteractive': false,
        'defaultParams': {
          'example': '+2 -1',
          'stepPauseSec': 2,
          'totalRods': 2,
        },
        'fields': [
          {
            'key': 'stepPauseSec',
            'type': 'number',
            'labelKey': 'stepPauseSecLabel',
            'min': 0.5,
            'max': 30,
          },
        ],
      });

      expect(config.fields.single.min, 0.5);
      expect(config.fields.single.max, 30);
    });
  });

  group('buildPlayParamsPayload', () {
    test('maps letter-grid-match admin form keys to trainer params', () {
      final config = TrainerPlayConfig.fromJson({
        'status': 'success',
        'trainerKey': 'letter-grid-match',
        'title': 'Grid match',
        'direction': 'reading',
        'isInteractive': true,
        'defaultParams': {
          'practiceLetters': 'А,М,К',
          'digit': 3,
          'entityCount': 5,
          'letterCase': 'upper',
        },
        'fields': [],
      });

      final payload = buildPlayParamsPayload(config, {
        'practiceLetters': 'А,М,К',
        'digit': '3',
        'entityCount': '5',
        'letterCase': 'upper',
      });

      expect(payload['gridSize'], 3);
      expect(payload['filledCount'], 5);
      expect(payload['practiceLetters'], 'А,М,К');
      expect(payload['letterCase'], 'upper');
      expect(payload.containsKey('digit'), isFalse);
      expect(payload.containsKey('entityCount'), isFalse);
    });

    test('maps topic-chain-flash chainTopicId to topicId', () {
      final config = TrainerPlayConfig.fromJson({
        'status': 'success',
        'trainerKey': 'topic-chain-flash',
        'title': 'Chain flash',
        'direction': 'mental',
        'isInteractive': true,
        'defaultParams': {
          'chainTopicId': 'simple-1',
          'actionCount': 5,
          'signMode': 'mix',
          'stepPauseSec': 1,
        },
        'fields': [],
      });

      final payload = buildPlayParamsPayload(config, {
        'chainTopicId': 'friend-9-1digit',
        'actionCount': '5',
        'signMode': 'mix',
        'stepPauseSec': '0.5',
      });

      expect(payload['topicId'], 'friend-9-1digit');
      expect(payload['actionCount'], 5);
      expect(payload['stepPauseSec'], 0.5);
      expect(payload.containsKey('chainTopicId'), isFalse);
      expect(payload.containsKey('amountScope'), isFalse);
    });

    test('builds flashcard values array fields for API', () {
      final config = TrainerPlayConfig.fromJson({
        'status': 'success',
        'trainerKey': 'flashcard-digit-match',
        'title': 'Flashcards',
        'direction': 'mental',
        'isInteractive': false,
        'defaultParams': {
          'pairCount': '3',
          'totalRods': 1,
          'value0': 0,
          'value1': 1,
          'value2': 2,
        },
        'fields': [],
      });

      final payload = buildPlayParamsPayload(config, {
        'pairCount': '3',
        'totalRods': '1',
        'value0': '0',
        'value1': '1',
        'value2': '2',
      });

      expect(payload['totalRods'], 1);
      expect(payload['values'], [0, 1, 2]);
    });
  });
}
