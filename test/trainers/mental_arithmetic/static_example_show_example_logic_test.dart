import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/static_example_show/example_logic.dart';

void main() {
  group('resolveStaticExampleAbacusValues', () {
    test('10 - 9 → left 10, right 1', () {
      expect(
        resolveStaticExampleAbacusValues(
          operation: 'subtract',
          operandA: 10,
          operandB: 9,
        ),
        (leftValue: 10, rightValue: 1),
      );
    });

    test('6 + 3 → left 6, right 9', () {
      expect(
        resolveStaticExampleAbacusValues(
          operation: 'add',
          operandA: 6,
          operandB: 3,
        ),
        (leftValue: 6, rightValue: 9),
      );
    });
  });

  group('formatStaticExampleExpression', () {
    test('formats subtraction with typographic minus', () {
      expect(
        formatStaticExampleExpression(
          operation: 'subtract',
          operandA: 10,
          operandB: 9,
        ),
        '10 − 9',
      );
    });

    test('formats addition', () {
      expect(
        formatStaticExampleExpression(
          operation: 'add',
          operandA: 6,
          operandB: 3,
        ),
        '6 + 3',
      );
    });
  });

  group('maxValueForRods', () {
    test('returns 9 for one rod', () {
      expect(maxValueForRods(1), 9);
    });

    test('returns 99 for two rods', () {
      expect(maxValueForRods(2), 99);
    });
  });
}
