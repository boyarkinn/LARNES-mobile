/// Web: `platform/src/trainers/mental-arithmetic/chain-generator/model.ts`

import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/types.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_model.dart';

class ChainModelError implements Exception {
  ChainModelError(this.message);

  final String message;

  @override
  String toString() => 'ChainModelError: $message';
}

int maxValueForRods(int totalRods) => getMaxValueForAbacusRods(totalRods);

void _applyAddDigit(List<RodState> rods, int rodIndex, int digit) {
  final current = beadsToDigit(rods[rodIndex]);

  if (current + digit > 9) {
    if (rodIndex <= 0) {
      throw ChainModelError('Значение не помещается в заданное число разрядов.');
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
      throw ChainModelError('Промежуточное значение отрицательное.');
    }

    _applySubtractDigit(rods, rodIndex - 1, 1);
    rods[rodIndex] = digitToBeads(current + 10 - digit);
    return;
  }

  rods[rodIndex] = digitToBeads(current - digit);
}

void _applyAmount(List<RodState> rods, int amount, String sign) {
  var remaining = amount < 0 ? 0 : amount;
  var rodIndex = rods.length - 1;

  while (remaining > 0) {
    if (rodIndex < 0) {
      throw ChainModelError(
        sign == '+'
            ? 'Значение не помещается в заданное число разрядов.'
            : 'Промежуточное значение отрицательное.',
      );
    }

    final digit = remaining % 10;

    if (digit > 0) {
      if (sign == '+') {
        _applyAddDigit(rods, rodIndex, digit);
      } else {
        _applySubtractDigit(rods, rodIndex, digit);
      }
    }

    remaining ~/= 10;
    rodIndex -= 1;
  }
}

int applyChainStep(int value, ChainStep step, int totalRods) {
  if (totalRods < 1 || totalRods > 3) {
    throw ChainModelError('totalRods must be 1, 2, or 3.');
  }

  if (step.amount < 1) {
    throw ChainModelError('step.amount must be an integer >= 1.');
  }

  final start = value < 0 ? 0 : value;

  if (start > maxValueForRods(totalRods)) {
    throw ChainModelError('Start value exceeds rod capacity.');
  }

  final rods = numberToAbacus(start, totalRods);
  _applyAmount(rods, step.amount, step.sign);
  final next = abacusToNumber(rods);

  if (next < 0 || next > maxValueForRods(totalRods)) {
    throw ChainModelError('Result out of rod bounds.');
  }

  return next;
}

int? tryApplyChainStep(int value, ChainStep step, int totalRods) {
  try {
    return applyChainStep(value, step, totalRods);
  } on ChainModelError {
    return null;
  }
}
