import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/catalog/trainer_param_validators.dart';
import 'package:larnes_mobile/trainers/intel/fly_track/definition.dart';
import 'package:larnes_mobile/trainers/runtime/validate_params.dart';

void main() {
  group('fly-track params', () {
    test('uses the agreed defaults', () {
      final result = validateFlyTrackParams({});

      expect(result.ok, isTrue);
      expect(result.params, {
        'gridSize': kFlyTrackGridSizeDefault,
        'rounds': kFlyTrackRoundsDefault,
        'stepCount': kFlyTrackStepCountDefault,
        'stepPauseSec': kFlyTrackStepPauseSecDefault,
      });
    });

    test('accepts the agreed parameter bounds', () {
      expect(
        validateFlyTrackParams({
          'gridSize': 3,
          'rounds': 10,
          'stepCount': 20,
          'stepPauseSec': 0.5,
        }).ok,
        isTrue,
      );
      expect(
        validateFlyTrackParams({
          'gridSize': 9,
          'rounds': 0,
          'stepCount': 21,
          'stepPauseSec': 0.4,
        }).ok,
        isFalse,
      );
    });

    test('validateTrainerParams roundtrips fly-track key', () {
      final result = validateTrainerParams('fly-track', {
        'gridSize': '4',
        'rounds': '2',
        'stepCount': '5',
        'stepPauseSec': '1.5',
      });

      expect(result.ok, isTrue);
      expect(result.params, {
        'gridSize': 4,
        'rounds': 2,
        'stepCount': 5,
        'stepPauseSec': 1.5,
      });
    });
  });
}
