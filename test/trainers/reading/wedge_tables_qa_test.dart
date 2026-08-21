import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/features/admin/models/trainer_play.dart';
import 'package:larnes_mobile/trainers/catalog/registry.dart';
import 'package:larnes_mobile/trainers/catalog/trainer_direction.dart';
import 'package:larnes_mobile/trainers/reading/wedge_tables/wedge_tables_audio.dart';
import 'package:larnes_mobile/trainers/runtime/trainer_player.dart';
import 'package:larnes_mobile/trainers/runtime/validate_params.dart';

void main() {
  group('wedge-tables QA parity', () {
    test('validates agreed defaults and bounds', () {
      final defaults = validateTrainerParams('wedge-tables', {});
      expect(defaults.ok, isTrue, reason: defaults.error);
      expect(defaults.params, {
        'category': 'digits',
        'displaySeconds': 2.0,
        'orientation': 'horizontal',
        'rounds': 1,
        'rowCount': 10,
      });

      final custom = validateTrainerParams('wedge-tables', {
        'category': 'syllables',
        'displaySeconds': 0.5,
        'orientation': 'vertical',
        'rounds': 2,
        'rowCount': 15,
      });
      expect(custom.ok, isTrue, reason: custom.error);
      expect(custom.params, {
        'category': 'syllables',
        'displaySeconds': 0.5,
        'orientation': 'vertical',
        'rounds': 2,
        'rowCount': 15,
      });

      expect(validateTrainerParams('wedge-tables', {'rowCount': 7}).ok, isFalse);
      expect(
        validateTrainerParams('wedge-tables', {'displaySeconds': 5.5}).ok,
        isFalse,
      );
    });

    test('admin play payload keeps native wedge params', () {
      final config = TrainerPlayConfig.fromJson({
        'status': 'success',
        'trainerKey': 'wedge-tables',
        'title': 'Клиновидная таблица',
        'direction': 'reading',
        'isInteractive': true,
        'defaultParams': {
          'category': 'digits',
          'displaySeconds': 2,
          'orientation': 'horizontal',
          'rounds': 1,
          'rowCount': 10,
        },
        'fields': [
          {'key': 'rounds', 'labelKey': 'roundsLabel', 'type': 'number'},
          {'key': 'rowCount', 'labelKey': 'wedgeRowCountLabel', 'type': 'select'},
          {
            'key': 'displaySeconds',
            'labelKey': 'wedgeDisplaySecondsLabel',
            'type': 'number',
          },
          {'key': 'category', 'labelKey': 'wedgeCategoryLabel', 'type': 'select'},
          {
            'key': 'orientation',
            'labelKey': 'wedgeOrientationLabel',
            'type': 'select',
          },
        ],
      });

      final payload = buildPlayParamsPayload(config, {
        'rounds': '2',
        'rowCount': '20',
        'displaySeconds': '1.5',
        'category': 'letters',
        'orientation': 'vertical',
      });

      expect(payload, {
        'rounds': 2,
        'rowCount': '20',
        'displaySeconds': 1.5,
        'category': 'letters',
        'orientation': 'vertical',
      });

      final validated = validateTrainerParams('wedge-tables', payload);
      expect(validated.ok, isTrue, reason: validated.error);
      expect(validated.params?['rowCount'], 20);
    });

    test('catalog wiring exposes interactive reading trainer with builder', () {
      final definition = getTrainerDefinition('wedge-tables');

      expect(definition?.title, 'Клиновидная таблица');
      expect(definition?.direction, TrainerDirection.reading);
      expect(definition?.isInteractive, isTrue);
      expect(hasTrainerBuilder('wedge-tables'), isTrue);
      expect(isTrainerInteractive('wedge-tables'), isTrue);
      expect(isTrainerKey('wedge-tables'), isTrue);
    });

    test('instruction clip is bundled and plays at 1.5x', () {
      expect(kWedgeTablesInstructionPlaybackRate, 1.5);
      expect(
        getWedgeTablesInstructionAudioAsset(),
        'audio/ru/reading/wedge-tables/instruction.mp3',
      );
      expect(
        File('assets/audio/ru/reading/wedge-tables/instruction.mp3').existsSync(),
        isTrue,
      );
    });

    test('scene has no on-screen instruction chrome', () {
      final trainerSource =
          File('lib/trainers/reading/wedge_tables/wedge_tables_trainer.dart')
              .readAsStringSync();

      expect(trainerSource, contains('WedgePhase.instruction'));
      expect(trainerSource, contains('playWedgeTablesInstruction'));
      expect(trainerSource, isNot(contains('Найди')));
      expect(trainerSource, isNot(contains('Молодец')));
      expect(trainerSource, isNot(contains('Готово')));
      expect(trainerSource, isNot(contains('countdown')));
    });
  });
}
