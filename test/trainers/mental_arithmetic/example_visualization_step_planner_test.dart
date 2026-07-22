import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/example_visualization/step_planner.dart';

void main() {
  group('planExampleSteps', () {
    test('+2 -1: values 0 → 2 → 1', () {
      final plan = planExampleSteps('+2 -1', 2);

      expect(plan.values, [0, 2, 1]);
      expect(plan.rodStates.length, 3);
    });

    test('regression examples match web', () {
      expect(planExampleSteps('+9 -1', 1).values, [0, 9, 8]);
      expect(planExampleSteps('+1 +9', 2).values, [0, 1, 10]);
      expect(planExampleSteps('+10 -1', 2).values, [0, 10, 9]);
    });

    test('rejects underflow and overflow', () {
      expect(
        () => planExampleSteps('+1 -2', 2),
        throwsA(isA<ExamplePlanError>()),
      );
      expect(
        () => planExampleSteps('+10 -1', 1),
        throwsA(isA<ExamplePlanError>()),
      );
    });
  });
}
