/// Web: `platform/src/trainers/mental-arithmetic/chain-generator/classify.ts`

import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/model.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/types.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_model.dart';

const _techniquePriority = {
  TechniqueKind.direct: 0,
  TechniqueKind.brother: 1,
  TechniqueKind.friend: 2,
  TechniqueKind.friendBrother: 3,
};

bool _isBrotherN(int n) => n >= 1 && n <= 4;

bool _isFriendN(int n) => n >= 1 && n <= 9;

bool _isFriendBrotherN(int n) => n >= 6 && n <= 9;

bool _subtractUsesBrother(int digit, int amount) {
  if (amount <= 0 || digit < amount) {
    return false;
  }

  final heavenUp = digit >= 5;
  final target = digit - amount;
  return heavenUp && target < 5;
}

bool _addUsesBrother(int digit, int amount) {
  if (amount <= 0 || amount > 4) {
    return false;
  }

  final heavenUp = digit >= 5;
  final earthCount = heavenUp ? digit - 5 : digit;
  return !heavenUp && earthCount + amount > 4;
}

Technique classifyAddDigit(int digit, int amount) {
  if (!_isFriendN(amount)) {
    throw ChainModelError('classifyAddDigit expects amount 1..9.');
  }

  final d = ((digit % 10) + 10) % 10;

  if (d + amount > 9) {
    final complement = 10 - amount;

    if (_isFriendBrotherN(amount) && _subtractUsesBrother(d, complement)) {
      return Technique.friendBrother(amount);
    }

    return Technique.friend(amount);
  }

  final heavenUp = d >= 5;
  final earthCount = heavenUp ? d - 5 : d;

  if (!heavenUp && earthCount + amount > 4) {
    if (amount > 5) {
      return const Technique.direct();
    }

    if (_isBrotherN(amount)) {
      return Technique.brother(amount);
    }
  }

  return const Technique.direct();
}

Technique classifySubDigit(int digit, int amount) {
  if (!_isFriendN(amount)) {
    throw ChainModelError('classifySubDigit expects amount 1..9.');
  }

  final d = ((digit % 10) + 10) % 10;

  if (d < amount) {
    final complement = 10 - amount;

    if (_isFriendBrotherN(amount) && _addUsesBrother(d, complement)) {
      return Technique.friendBrother(amount);
    }

    return Technique.friend(amount);
  }

  if (_isBrotherN(amount) && _subtractUsesBrother(d, amount)) {
    return Technique.brother(amount);
  }

  return const Technique.direct();
}

Technique _pickStronger(Technique left, Technique right) {
  return (_techniquePriority[right.kind] ?? 0) > (_techniquePriority[left.kind] ?? 0)
      ? right
      : left;
}

int _pow10(int place) {
  var result = 1;
  for (var i = 0; i < place; i++) {
    result *= 10;
  }
  return result;
}

class PlaceTechnique {
  const PlaceTechnique({
    required this.digitAmount,
    required this.place,
    required this.technique,
  });

  final int digitAmount;
  final int place;
  final Technique technique;
}

/// Поразрядная классификация — чтобы не пропускать чужой brother/friend на другом стержне.
List<PlaceTechnique> classifyStepPlaces(
  int value,
  ChainStep step,
  int totalRods,
) {
  applyChainStep(value, step, totalRods);

  var currentValue = value < 0 ? 0 : value;
  var remaining = step.amount;
  var place = 0;
  final places = <PlaceTechnique>[];

  while (remaining > 0) {
    final digitAmount = remaining % 10;

    if (digitAmount > 0) {
      final placeValue = digitAmount * _pow10(place);
      final micro = ChainStep(amount: placeValue, sign: step.sign);
      final rods = numberToAbacus(currentValue, totalRods);
      final rodIndex = rods.length - 1 - place;

      if (rodIndex < 0) {
        throw ChainModelError('Значение не помещается в заданное число разрядов.');
      }

      final digit = beadsToDigit(rods[rodIndex]);
      final technique = step.sign == '+'
          ? classifyAddDigit(digit, digitAmount)
          : classifySubDigit(digit, digitAmount);
      places.add(
        PlaceTechnique(
          digitAmount: digitAmount,
          place: place,
          technique: technique,
        ),
      );
      currentValue = applyChainStep(currentValue, micro, totalRods);
    }

    remaining ~/= 10;
    place += 1;
  }

  return places;
}

bool everyPlaceTechnique(
  int value,
  ChainStep step,
  int totalRods,
  bool Function(Technique technique) predicate,
) {
  final places = classifyStepPlaces(value, step, totalRods);
  return places.isNotEmpty &&
      places.every((entry) => predicate(entry.technique));
}

/// Focus-техника на разряде place ≥ minPlace (десятки/сотни).
bool chainHasFocusTechniqueOnPlaceAtLeast(
  List<ChainStep> steps,
  List<int> intermediates,
  int totalRods,
  int minPlace,
  bool Function(Technique technique) isFocus,
) {
  for (var index = 0; index < steps.length; index += 1) {
    final places =
        classifyStepPlaces(intermediates[index], steps[index], totalRods);
    if (places.any(
      (entry) => entry.place >= minPlace && isFocus(entry.technique),
    )) {
      return true;
    }
  }
  return false;
}

bool chainHasFocusTechniqueOnExactPlace(
  List<ChainStep> steps,
  List<int> intermediates,
  int totalRods,
  int exactPlace,
  bool Function(Technique technique) isFocus,
) {
  for (var index = 0; index < steps.length; index += 1) {
    final places =
        classifyStepPlaces(intermediates[index], steps[index], totalRods);
    if (places.any(
      (entry) => entry.place == exactPlace && isFocus(entry.technique),
    )) {
      return true;
    }
  }
  return false;
}

/// ones+higher обычно нужны ≥2 focus-слота (len~/2 ≥ 2 → len≥4).
bool shouldEnforceFocusOnOnesAndHigher(int stepCount) {
  return stepCount ~/ 2 >= 2;
}

/// Focus и на единицах (закрепление), и на старших разрядах.
bool chainHasFocusOnOnesAndHigherPlaces(
  List<ChainStep> steps,
  List<int> intermediates,
  int totalRods,
  bool Function(Technique technique) isFocus,
) {
  return chainHasFocusTechniqueOnExactPlace(
        steps,
        intermediates,
        totalRods,
        0,
        isFocus,
      ) &&
      chainHasFocusTechniqueOnPlaceAtLeast(
        steps,
        intermediates,
        totalRods,
        1,
        isFocus,
      );
}

Technique classifyStep(int value, ChainStep step, int totalRods) {
  final places = classifyStepPlaces(value, step, totalRods);
  var result = const Technique.direct();
  for (final entry in places) {
    result = _pickStronger(result, entry.technique);
  }
  return result;
}
