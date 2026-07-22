import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/catalog/trainer_param_validators.dart';
import 'package:larnes_mobile/trainers/runtime/validate_params.dart';

void main() {
  group('validateExampleVisualizationParams', () {
    test('accepts default admin params', () {
      final result = validateExampleVisualizationParams({
        'example': '+2 -1',
        'stepPauseSec': 2,
        'totalRods': 2,
      });

      expect(result.ok, isTrue);
      expect(result.params, {
        'example': '+2 -1',
        'stepPauseSec': 2,
        'totalRods': 2,
      });
    });

    test('accepts spaced example and coerced strings', () {
      final result = validateTrainerParams('example-visualization', {
        'example': '+2 - 1',
        'stepPauseSec': '1.5',
        'totalRods': '1',
      });

      expect(result.ok, isTrue);
      expect(result.params, {
        'example': '+2 -1',
        'stepPauseSec': 1.5,
        'totalRods': 1,
      });
    });

    test('rejects overflow for one rod', () {
      final result = validateExampleVisualizationParams({
        'example': '+10 -1',
        'stepPauseSec': 2,
        'totalRods': 1,
      });

      expect(result.ok, isFalse);
      expect(result.error, contains('9'));
    });
  });
}
