import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/features/admin/models/trainer_play.dart';
import 'package:larnes_mobile/trainers/catalog/registry.dart';
import 'package:larnes_mobile/trainers/catalog/trainer_direction.dart';
import 'package:larnes_mobile/trainers/reading/schulte_table/schulte_table_audio.dart';
import 'package:larnes_mobile/trainers/runtime/trainer_player.dart';
import 'package:larnes_mobile/trainers/runtime/validate_params.dart';

void main() {
  group('schulte-table QA parity', () {
    test('validates agreed defaults and bounds', () {
      final defaults = validateTrainerParams('schulte-table', {});
      expect(defaults.ok, isTrue, reason: defaults.error);
      expect(defaults.params, {
        'category': 'digits',
        'centerDot': false,
        'gridSize': 5,
        'order': 'forward',
        'rounds': 1,
        'showFound': false,
        'symbolOrientation': 'normal',
      });

      final custom = validateTrainerParams('schulte-table', {
        'category': 'letters',
        'centerDot': 'yes',
        'gridSize': 8,
        'order': 'backward',
        'rounds': 3,
        'showFound': true,
        'symbolOrientation': 'upside-down',
      });
      expect(custom.ok, isTrue, reason: custom.error);
      expect(custom.params, {
        'category': 'letters',
        'centerDot': true,
        'gridSize': 8,
        'order': 'backward',
        'rounds': 3,
        'showFound': true,
        'symbolOrientation': 'upside-down',
      });

      expect(validateTrainerParams('schulte-table', {'gridSize': 2}).ok, isFalse);
      expect(
        validateTrainerParams('schulte-table', {
          'category': 'letters',
          'gridSize': 9,
        }).ok,
        isFalse,
      );
    });

    test('accepts homework form aliases', () {
      final validated = validateTrainerParams('schulte-table', {
        'digit': 6,
        'wordSlug': 'letters',
        'missingSegment': 'backward',
        'wordCase': 'upside-down',
        'value2': 'yes',
        'value3': 'no',
        'rounds': 2,
      });

      expect(validated.ok, isTrue, reason: validated.error);
      expect(validated.params, {
        'category': 'letters',
        'centerDot': true,
        'gridSize': 6,
        'order': 'backward',
        'rounds': 2,
        'showFound': false,
        'symbolOrientation': 'upside-down',
      });
    });

    test('admin play payload keeps native schulte params', () {
      final config = TrainerPlayConfig.fromJson({
        'status': 'success',
        'trainerKey': 'schulte-table',
        'title': 'Таблица Шульте',
        'direction': 'reading',
        'isInteractive': true,
        'defaultParams': {
          'category': 'digits',
          'centerDot': 'no',
          'gridSize': 5,
          'order': 'forward',
          'rounds': 1,
          'showFound': 'no',
          'symbolOrientation': 'normal',
        },
        'fields': [
          {'key': 'rounds', 'labelKey': 'roundsLabel', 'type': 'number'},
          {'key': 'gridSize', 'labelKey': 'schulteGridSizeLabel', 'type': 'number'},
          {'key': 'category', 'labelKey': 'schulteCategoryLabel', 'type': 'select'},
          {'key': 'order', 'labelKey': 'schulteOrderLabel', 'type': 'select'},
          {
            'key': 'symbolOrientation',
            'labelKey': 'schulteOrientationLabel',
            'type': 'select',
          },
          {'key': 'centerDot', 'labelKey': 'schulteCenterDotLabel', 'type': 'select'},
          {'key': 'showFound', 'labelKey': 'schulteShowFoundLabel', 'type': 'select'},
        ],
      });

      final payload = buildPlayParamsPayload(config, {
        'rounds': '2',
        'gridSize': '4',
        'category': 'letters',
        'order': 'backward',
        'symbolOrientation': 'upside-down',
        'centerDot': 'yes',
        'showFound': 'yes',
      });

      expect(payload, {
        'rounds': 2,
        'gridSize': 4,
        'category': 'letters',
        'order': 'backward',
        'symbolOrientation': 'upside-down',
        'centerDot': 'yes',
        'showFound': 'yes',
      });

      final validated = validateTrainerParams('schulte-table', payload);
      expect(validated.ok, isTrue, reason: validated.error);
      expect(validated.params?['centerDot'], isTrue);
      expect(validated.params?['showFound'], isTrue);
    });

    test('catalog wiring exposes interactive reading trainer with builder', () {
      final definition = getTrainerDefinition('schulte-table');

      expect(definition?.title, 'Таблица Шульте');
      expect(definition?.direction, TrainerDirection.reading);
      expect(definition?.isInteractive, isTrue);
      expect(hasTrainerBuilder('schulte-table'), isTrue);
      expect(isTrainerInteractive('schulte-table'), isTrue);
      expect(isTrainerKey('schulte-table'), isTrue);
    });

    test('instruction clip is bundled and plays at 1.5x', () {
      expect(kSchulteTableInstructionPlaybackRate, 1.5);
      expect(
        getSchulteTableInstructionAudioAsset(),
        'audio/ru/reading/schulte-table/instruction.mp3',
      );
      expect(
        File('assets/audio/ru/reading/schulte-table/instruction.mp3').existsSync(),
        isTrue,
      );
    });

    test('scene has no on-screen instruction chrome', () {
      final trainerSource =
          File('lib/trainers/reading/schulte_table/schulte_table_trainer.dart')
              .readAsStringSync();

      expect(trainerSource, contains('SchultePhase.instruction'));
      expect(trainerSource, contains('playSchulteTableInstruction'));
      expect(trainerSource, isNot(contains('Найди')));
      expect(trainerSource, isNot(contains('Молодец')));
      expect(trainerSource, isNot(contains('countdown')));
    });
  });
}
