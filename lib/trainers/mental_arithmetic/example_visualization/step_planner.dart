/// Web: `platform/src/trainers/mental-arithmetic/example-visualization/step-planner.ts`

import 'package:larnes_mobile/trainers/mental_arithmetic/example_visualization/example_parser.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_model.dart';

class ExampleStepPlan {
  const ExampleStepPlan({
    required this.actions,
    required this.rodStates,
    required this.values,
  });

  final List<ExampleAction> actions;
  final List<List<RodState>> rodStates;
  final List<int> values;
}

class ExamplePlanError implements Exception {
  ExamplePlanError(this.message);

  final String message;

  @override
  String toString() => message;
}

List<RodState> cloneExampleRods(List<RodState> rods) {
  return rods
      .map(
        (rod) => RodState(
          heavenUp: rod.heavenUp,
          earthCount: rod.earthCount,
        ),
      )
      .toList();
}

void _applyAddition(List<RodState> rods, int amount) {
  var remaining = amount < 0 ? 0 : amount;
  var rodIndex = rods.length - 1;

  while (remaining > 0) {
    if (rodIndex < 0) {
      throw ExamplePlanError(
        'Пример не помещается в заданное число разрядов.',
      );
    }

    final digit = remaining % 10;

    if (digit > 0) {
      _applyAddDigit(rods, rodIndex, digit);
    }

    remaining ~/= 10;
    rodIndex -= 1;
  }
}

void _applySubtraction(List<RodState> rods, int amount) {
  var remaining = amount < 0 ? 0 : amount;
  var rodIndex = rods.length - 1;

  while (remaining > 0) {
    if (rodIndex < 0) {
      throw ExamplePlanError('После действия значение отрицательное.');
    }

    final digit = remaining % 10;

    if (digit > 0) {
      _applySubtractDigit(rods, rodIndex, digit);
    }

    remaining ~/= 10;
    rodIndex -= 1;
  }
}

void _applyAddDigit(List<RodState> rods, int rodIndex, int digit) {
  final current = beadsToDigit(rods[rodIndex]);

  if (current + digit > 9) {
    if (rodIndex <= 0) {
      throw ExamplePlanError(
        'Пример не помещается в заданное число разрядов.',
      );
    }

    _applyAddDigit(rods, rodIndex - 1, 1);
    rods[rodIndex] = digitToBeads(current + digit - 10);
    return;
  }

  rods[rodIndex] = digitToBeads(current + digit);
}

void _applySubtractDigit(List<RodState> rods, int rodIndex, int digit) {
  final current = beadsToDigit(rods[rodIndex]);

  if (current < digit) {
    if (rodIndex <= 0) {
      throw ExamplePlanError('После действия значение отрицательное.');
    }

    _applySubtractDigit(rods, rodIndex - 1, 1);
    rods[rodIndex] = digitToBeads(current + 10 - digit);
    return;
  }

  rods[rodIndex] = digitToBeads(current - digit);
}

void _applyAction(List<RodState> rods, ExampleAction action) {
  if (action.sign == '+') {
    _applyAddition(rods, action.digit);
  } else {
    _applySubtraction(rods, action.digit);
  }
}

ExampleStepPlan planExampleSteps(String example, int totalRods) {
  final actions = parseExampleActions(example);
  final rods = numberToAbacus(0, totalRods);
  final rodStates = <List<RodState>>[cloneExampleRods(rods)];

  for (final action in actions) {
    _applyAction(rods, action);
    rodStates.add(cloneExampleRods(rods));
  }

  final values = rodStates.map(abacusToNumber).toList();

  return ExampleStepPlan(
    actions: actions,
    rodStates: rodStates,
    values: values,
  );
}

String? validateExamplePlan(String example, int totalRods) {
  try {
    planExampleSteps(example, totalRods);
    return null;
  } on ExamplePlanError catch (error) {
    return error.message;
  } catch (_) {
    return 'Неверный пример.';
  }
}
