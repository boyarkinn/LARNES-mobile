import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/catalog/trainer_param_validators.dart';
import 'package:larnes_mobile/trainers/runtime/validate_params.dart';

void main() {
  group('validateStaticExampleShowParams', () {
    test('accepts valid addition params', () {
      final result = validateStaticExampleShowParams({
        'operation': 'add',
        'operandA': 6,
        'operandB': 3,
        'totalRods': 2,
      });

      expect(result.ok, isTrue);
      expect(result.params, {
        'operation': 'add',
        'operandA': 6,
        'operandB': 3,
        'totalRods': 2,
      });
    });

    test('accepts coerced string params', () {
      final result = validateTrainerParams('static-example-show', {
        'operation': 'subtract',
        'operandA': '10',
        'operandB': '9',
        'totalRods': '2',
      });

      expect(result.ok, isTrue);
      expect(result.params, {
        'operation': 'subtract',
        'operandA': 10,
        'operandB': 9,
        'totalRods': 2,
      });
    });

    test('rejects subtract when operandA < operandB', () {
      final result = validateStaticExampleShowParams({
        'operation': 'subtract',
        'operandA': 3,
        'operandB': 5,
        'totalRods': 1,
      });

      expect(result.ok, isFalse);
      expect(
        result.error,
        'При вычитании первое число не может быть меньше второго.',
      );
    });

    test('rejects value that does not fit rods', () {
      final result = validateStaticExampleShowParams({
        'operation': 'add',
        'operandA': 9,
        'operandB': 9,
        'totalRods': 1,
      });

      expect(result.ok, isFalse);
      expect(
        result.error,
        'Ответ не помещается в 1 разряд(ов) (макс. 9)',
      );
    });
  });
}
