import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/features/admin/models/trainer_play.dart';
import 'package:larnes_mobile/trainers/catalog/registry.dart';
import 'package:larnes_mobile/trainers/catalog/trainer_direction.dart';
import 'package:larnes_mobile/trainers/reading/stroop_colors/stroop_colors_audio.dart';
import 'package:larnes_mobile/trainers/runtime/trainer_player.dart';
import 'package:larnes_mobile/trainers/runtime/validate_params.dart';

void main() {
  group('stroop-colors QA parity', () {
    test('validates agreed defaults and bounds', () {
      final defaults = validateTrainerParams('stroop-colors', {});
      expect(defaults.ok, isTrue, reason: defaults.error);
      expect(defaults.params, {
        'displaySeconds': 3.0,
        'wordCount': 8,
      });

      final custom = validateTrainerParams('stroop-colors', {
        'displaySeconds': 2.5,
        'wordCount': 12,
      });
      expect(custom.ok, isTrue, reason: custom.error);
      expect(custom.params, {
        'displaySeconds': 2.5,
        'wordCount': 12,
      });

      expect(validateTrainerParams('stroop-colors', {'wordCount': 0}).ok, isFalse);
      expect(
        validateTrainerParams('stroop-colors', {'displaySeconds': 11}).ok,
        isFalse,
      );
    });

    test('admin play payload keeps wordCount and displaySeconds', () {
      final config = TrainerPlayConfig.fromJson({
        'status': 'success',
        'trainerKey': 'stroop-colors',
        'title': 'Струп-тест',
        'direction': 'reading',
        'isInteractive': true,
        'defaultParams': {
          'wordCount': 8,
          'displaySeconds': 3,
        },
        'fields': [
          {
            'key': 'wordCount',
            'labelKey': 'wordCountLabel',
            'type': 'number',
          },
          {
            'key': 'displaySeconds',
            'labelKey': 'stroopDisplaySecondsLabel',
            'type': 'number',
          },
        ],
      });

      final payload = buildPlayParamsPayload(config, {
        'wordCount': '6',
        'displaySeconds': '4',
      });

      expect(payload, {
        'wordCount': 6,
        'displaySeconds': 4,
      });

      final validated = validateTrainerParams('stroop-colors', payload);
      expect(validated.ok, isTrue, reason: validated.error);
    });

    test('catalog wiring exposes interactive reading trainer with builder', () {
      final definition = getTrainerDefinition('stroop-colors');

      expect(definition?.title, 'Струп-тест');
      expect(definition?.direction, TrainerDirection.reading);
      expect(definition?.isInteractive, isTrue);
      expect(hasTrainerBuilder('stroop-colors'), isTrue);
      expect(isTrainerInteractive('stroop-colors'), isTrue);
      expect(isTrainerKey('stroop-colors'), isTrue);
    });

    test('instruction clip is bundled at 1x', () {
      expect(kStroopColorsInstructionPlaybackRate, 1);
      expect(
        getStroopColorsInstructionAudioAsset(),
        'audio/ru/reading/stroop-colors/instruction.mp3',
      );
      expect(
        File('assets/audio/ru/reading/stroop-colors/instruction.mp3').existsSync(),
        isTrue,
      );
    });

    test('scene has no on-screen instruction chrome', () {
      final trainerSource =
          File('lib/trainers/reading/stroop_colors/stroop_colors_trainer.dart')
              .readAsStringSync();

      expect(trainerSource, contains('StroopPhase.instruction'));
      expect(trainerSource, contains('playStroopColorsInstruction'));
      expect(trainerSource, isNot(contains('Colors.white')));
      expect(trainerSource, isNot(contains('Назови')));
      expect(trainerSource, isNot(contains('Молодец')));
      expect(trainerSource, isNot(contains('countdown')));
    });
  });
}
