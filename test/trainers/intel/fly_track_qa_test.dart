import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/features/admin/models/trainer_play.dart';
import 'package:larnes_mobile/trainers/catalog/registry.dart';
import 'package:larnes_mobile/trainers/catalog/trainer_direction.dart';
import 'package:larnes_mobile/trainers/intel/fly_track/fly_track_audio.dart';
import 'package:larnes_mobile/trainers/intel/fly_track/model.dart';
import 'package:larnes_mobile/trainers/runtime/trainer_player.dart';
import 'package:larnes_mobile/trainers/runtime/validate_params.dart';

const _uatGridSizes = [3, 4, 8];
const _uatRounds = [1, 2, 3];

void main() {
  group('fly-track QA parity (progon 1.5)', () {
    for (final gridSize in _uatGridSizes) {
      for (final rounds in _uatRounds) {
        test('validates and generates ${gridSize}x$gridSize with $rounds rounds', () {
          final validated = validateTrainerParams('fly-track', {
            'gridSize': gridSize,
            'rounds': rounds,
            'stepCount': 5,
            'stepPauseSec': 1.5,
          });

          expect(validated.ok, isTrue, reason: validated.error);

          final generated = generateFlyTrackRounds(
            GenerateFlyTrackRoundsInput(
              gridSize: gridSize,
              rounds: rounds,
              stepCount: 5,
              random: seededRandom(20260819 + gridSize * 10 + rounds),
            ),
          );

          expect(generated.length, rounds);
          for (final round in generated) {
            expect(round.steps.length, 5);
            expect(round.path.length, 6);
            expect(
              round.path.every((cell) => isFlyCellInGrid(cell, gridSize)),
              isTrue,
            );
          }
        });
      }
    }

    test('admin play payload maps digit to gridSize like web homework', () {
      final config = TrainerPlayConfig.fromJson({
        'status': 'success',
        'trainerKey': 'fly-track',
        'title': 'Муха',
        'direction': 'intel',
        'isInteractive': true,
        'defaultParams': {
          'digit': 4,
          'rounds': 1,
          'stepCount': 5,
          'stepPauseSec': 1.5,
        },
        'fields': [],
      });

      final payload = buildPlayParamsPayload(config, {
        'digit': '8',
        'rounds': '3',
        'stepCount': '7',
        'stepPauseSec': '2',
      });

      expect(payload, {
        'gridSize': 8,
        'rounds': 3,
        'stepCount': 7,
        'stepPauseSec': 2.0,
      });

      final validated = validateTrainerParams('fly-track', payload);
      expect(validated.ok, isTrue, reason: validated.error);
    });

    test('catalog wiring exposes interactive intel trainer with builder', () {
      final definition = getTrainerDefinition('fly-track');

      expect(definition?.title, 'Муха');
      expect(definition?.direction, TrainerDirection.intel);
      expect(definition?.isInteractive, isTrue);
      expect(hasTrainerBuilder('fly-track'), isTrue);
      expect(isTrainerInteractive('fly-track'), isTrue);
      expect(isTrainerKey('fly-track'), isTrue);
    });

    test('agreed timing and audio constants match web v1', () {
      expect(kFlyTrackAudioPlaybackRate, 1.5);

      final trainerSource =
          File('lib/trainers/intel/fly_track/fly_track_trainer.dart')
              .readAsStringSync();

      expect(trainerSource, contains('_countdownStepMs = 750'));
      expect(trainerSource, contains('_feedbackMs = 1600'));
      expect(trainerSource, contains('includeFlyMoved: stepIndex == 0'));
    });

    test('move audio contract matches web first-step vs later steps', () {
      expect(
        getFlyTrackMoveAudioAssets('up', 4, includeFlyMoved: true),
        contains('audio/ru/intel/fly-track/fly-moved.mp3'),
      );
      expect(
        getFlyTrackMoveAudioAssets('left', 2, includeFlyMoved: false),
        isNot(contains('audio/ru/intel/fly-track/fly-moved.mp3')),
      );
    });
  });
}
