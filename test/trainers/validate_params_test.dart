import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/catalog/trainer_param_validators.dart';
import 'package:larnes_mobile/trainers/runtime/validate_params.dart';

void main() {
  group('validateTrainerParams', () {
    test('accepts number-row-show params', () {
      final result = validateTrainerParams('number-row-show', {'digit': 5});
      expect(result.ok, isTrue);
      expect(result.params, {'digit': 5});
    });

    test('coerces string digits', () {
      final result = validateTrainerParams('number-row-show', {'digit': '3'});
      expect(result.ok, isTrue);
      expect(result.params, {'digit': 3});
    });

    test('rejects unknown trainer', () {
      final result = validateTrainerParams('missing-trainer', {});
      expect(result.ok, isFalse);
    });

    test('rejects invalid digit-find-tap field size', () {
      final result = validateTrainerParams('digit-find-tap', {
        'digit': 1,
        'targetCount': 20,
        'distractorCount': 20,
      });
      expect(result.ok, isFalse);
    });
  });
}
