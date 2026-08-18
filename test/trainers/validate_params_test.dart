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

    test('registered reading key is known to registry', () {
      final result = validateTrainerParams('letter-marquee-tap', {
        'practiceLetters': 'А, Б',
        'targetCount': 3,
      });
      expect(result.ok, isTrue);
    });

    test('rejects invalid digit-find-tap field size', () {
      final result = validateTrainerParams('digit-find-tap', {
        'digit': 1,
        'targetCount': 20,
        'distractorCount': 20,
      });
      expect(result.ok, isFalse);
    });

    test('accepts flashcard-digit-match admin form fields', () {
      final result = validateTrainerParams('flashcard-digit-match', {
        'pairCount': '3',
        'totalRods': '1',
        'value0': '0',
        'value1': '1',
        'value2': '2',
      });

      expect(result.ok, isTrue);
      expect(result.params, {
        'totalRods': 1,
        'values': [0, 1, 2],
      });
    });

    test('accepts flashcard-digit-match API values array', () {
      final result = validateTrainerParams('flashcard-digit-match', {
        'totalRods': 2,
        'values': [3, 7],
      });

      expect(result.ok, isTrue);
      expect(result.params, {
        'totalRods': 2,
        'values': [3, 7],
      });
    });

    test('accepts fly-track params with defaults', () {
      final result = validateTrainerParams('fly-track', {});

      expect(result.ok, isTrue);
      expect(result.params?['gridSize'], 4);
      expect(result.params?['rounds'], 1);
      expect(result.params?['stepCount'], 5);
      expect(result.params?['stepPauseSec'], 1.5);
    });
  });
}
