// Dart counterpart of web `abacus-show/movement-plan.ts`.
// Produces physical gestures for any mental-arithmetic trainer with an abacus.
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/abacus_playback_plan.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/example_parser.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_model.dart';

enum _Method { direct, fiveComplement, tenComplement, tenAndFive }

class _Movement {
  const _Movement({
    required this.actionIndex,
    required this.method,
    required this.rodIndices,
    required this.rods,
    required this.value,
  });

  final int actionIndex;
  final _Method method;
  final List<int> rodIndices;
  final List<RodState> rods;
  final int value;

  AbacusGestureFrame toGesture() => AbacusGestureFrame(
    actionIndex: actionIndex,
    rodIndices: rodIndices,
    rods: rods,
    value: value,
  );
}

AbacusPlaybackPlan planAbacusMovements(String example, int totalRods) {
  if (totalRods < 1 || totalRods > 3) {
    throw ArgumentError('Цифровой абакус поддерживает от 1 до 3 разрядов.');
  }
  final validationError = validateExampleForRods(example, totalRods);
  if (validationError != null) throw FormatException(validationError);

  final actions = parseExampleActions(example);
  final rods = numberToAbacus(0, totalRods);
  final gestures = <AbacusGestureFrame>[];
  final actionMovements = <_Movement>[];
  var actionIndex = 0;
  var hasCrossRodTransfer = false;

  void move(int rodIndex, RodState next, _Method method) {
    final before = rods[rodIndex];
    if (before == next) return;
    if (next.earthCount < 0 || next.earthCount > 4) {
      throw StateError('Невозможное положение нижних косточек.');
    }
    rods[rodIndex] = next;
    actionMovements.add(
      _Movement(
        actionIndex: actionIndex,
        method: method,
        rodIndices: [rodIndex],
        rods: List.of(rods),
        value: abacusToNumber(rods),
      ),
    );
  }

  void appendGesture(List<_Movement> group) {
    final last = group.last;
    gestures.add(
      AbacusGestureFrame(
        actionIndex: actionIndex,
        rodIndices: [for (final movement in group) ...movement.rodIndices],
        rods: last.rods,
        value: last.value,
      ),
    );
  }

  bool isTenComplement(_Movement movement) =>
      movement.method == _Method.tenComplement ||
      movement.method == _Method.tenAndFive;

  void addWithin(int rodIndex, int amount, _Method method) {
    final current = rods[rodIndex];
    final digit = beadsToDigit(current);
    final target = digit + amount;
    if (target > 9) throw StateError('Ошибка переноса разряда.');
    final crossesFiveWithComplement =
        !current.heavenUp && target >= 5 && amount <= 4;
    final movementMethod = crossesFiveWithComplement
        ? method == _Method.tenComplement
              ? _Method.tenAndFive
              : _Method.fiveComplement
        : method;
    move(rodIndex, digitToBeads(target), movementMethod);
  }

  void subtractWithin(int rodIndex, int amount, _Method method) {
    final current = rods[rodIndex];
    final digit = beadsToDigit(current);
    final target = digit - amount;
    if (target < 0) throw StateError('Ошибка займа разряда.');
    final crossesFiveWithComplement =
        current.heavenUp && target < 5 && amount <= 4;
    final movementMethod = crossesFiveWithComplement
        ? method == _Method.tenComplement
              ? _Method.tenAndFive
              : _Method.fiveComplement
        : method;
    move(rodIndex, digitToBeads(target), movementMethod);
  }

  void addDigit(int rodIndex, int amount, [_Method method = _Method.direct]) {
    final digit = beadsToDigit(rods[rodIndex]);
    if (digit + amount <= 9) {
      addWithin(rodIndex, amount, method);
      return;
    }
    if (rodIndex == 0) throw StateError('Пример не помещается на абакусе.');
    hasCrossRodTransfer = true;
    addDigit(rodIndex - 1, 1, _Method.tenComplement);
    subtractWithin(rodIndex, 10 - amount, _Method.tenComplement);
  }

  void subtractDigit(
    int rodIndex,
    int amount, [
    _Method method = _Method.direct,
  ]) {
    final digit = beadsToDigit(rods[rodIndex]);
    if (digit >= amount) {
      subtractWithin(rodIndex, amount, method);
      return;
    }
    if (rodIndex == 0) {
      throw StateError('После действия значение отрицательное.');
    }
    hasCrossRodTransfer = true;
    subtractDigit(rodIndex - 1, 1, _Method.tenComplement);
    addWithin(rodIndex, 10 - amount, _Method.tenComplement);
  }

  var expected = 0;
  for (var index = 0; index < actions.length; index++) {
    final action = actions[index];
    actionIndex = index;
    hasCrossRodTransfer = false;
    actionMovements.clear();
    final digits = action.digit.toString().padLeft(totalRods, '0');
    for (var rodIndex = 0; rodIndex < totalRods; rodIndex++) {
      final amount = int.parse(digits[rodIndex]);
      if (amount == 0) continue;
      if (action.sign == '+') {
        addDigit(rodIndex, amount);
      } else {
        subtractDigit(rodIndex, amount);
      }
    }

    if (!hasCrossRodTransfer) {
      final hundredsFirst =
          totalRods == 3 &&
          actionMovements.isNotEmpty &&
          actionMovements.first.rodIndices.first == 0;
      if (hundredsFirst) gestures.add(actionMovements.first.toGesture());
      for (
        var step = hundredsFirst ? 1 : 0;
        step < actionMovements.length;
        step += 2
      ) {
        final end = (step + 2).clamp(0, actionMovements.length);
        appendGesture(actionMovements.sublist(step, end));
      }
    } else {
      for (var step = 0; step < actionMovements.length;) {
        final first = actionMovements[step];
        final second = step + 1 < actionMovements.length
            ? actionMovements[step + 1]
            : null;
        if (second != null &&
            first.rodIndices.first == totalRods - 2 &&
            second.rodIndices.first == totalRods - 1 &&
            isTenComplement(first) &&
            isTenComplement(second)) {
          appendGesture([first, second]);
          step += 2;
        } else {
          gestures.add(first.toGesture());
          step++;
        }
      }
    }

    expected += action.sign == '+' ? action.digit : -action.digit;
    if (abacusToNumber(rods) != expected) {
      throw StateError(
        'Не удалось разложить ${formatExampleAction(action)} на движения косточек.',
      );
    }
  }

  return AbacusPlaybackPlan(actions: actions, gestures: gestures);
}
