import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/features/admin/models/trainer_play.dart';
import 'package:larnes_mobile/trainers/catalog/registry.dart';

void main() {
  group('mobile play gate', () {
    test('dots-digit-abacus has native builder', () {
      expect(hasTrainerBuilder('dots-digit-abacus'), isTrue);
    });

    test('letter-find-tap is registered without native builder', () {
      expect(isTrainerKey('letter-find-tap'), isTrue);
      expect(hasTrainerBuilder('letter-find-tap'), isFalse);
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
  });

  group('buildPlayParamsPayload', () {
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
