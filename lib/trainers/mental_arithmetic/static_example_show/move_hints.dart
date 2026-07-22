/// Web v2: `platform/src/trainers/mental-arithmetic/static-example-show/move-hints.ts`

import 'package:larnes_mobile/trainers/mental_arithmetic/static_example_show/example_logic.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_model.dart';

abstract final class MoveOverlayKind {
  static const earthToBar = 'earth-to-bar';
  static const earthFromBar = 'earth-from-bar';
  static const heavenToBar = 'heaven-to-bar';
  static const heavenFromBar = 'heaven-from-bar';
}

class MoveOverlay {
  const MoveOverlay({
    required this.kind,
    required this.rodIndex,
  });

  final String kind;
  final int rodIndex;
}

List<MoveOverlay> resolveMoveOverlays({
  required StaticExampleOperation operation,
  required int operandA,
  required int operandB,
  required int totalRods,
}) {
  final rods = numberToAbacus(operandA, totalRods);

  if (operation == 'add') {
    return overlaysForAddition(rods, operandB);
  }

  return overlaysForSubtraction(rods, operandB);
}

List<MoveOverlay> overlaysForAddition(List<RodState> rods, int operandB) {
  final overlays = <MoveOverlay>[];
  var remaining = operandB < 0 ? 0 : operandB.truncate();
  var rodIndex = rods.length - 1;

  while (remaining > 0 && rodIndex >= 0) {
    final digit = remaining % 10;

    if (digit > 0) {
      overlays.addAll(addDigitOverlays(rodIndex, digit, rods));
      applyAddDigit(rods, rodIndex, digit);
    }

    remaining ~/= 10;
    rodIndex -= 1;
  }

  return overlays;
}

List<MoveOverlay> overlaysForSubtraction(List<RodState> rods, int operandB) {
  final overlays = <MoveOverlay>[];
  var remaining = operandB < 0 ? 0 : operandB.truncate();
  var rodIndex = rods.length - 1;

  while (remaining > 0 && rodIndex >= 0) {
    final digit = remaining % 10;

    if (digit > 0) {
      overlays.addAll(subtractDigitOverlays(rodIndex, digit, rods));
      applySubtractDigit(rods, rodIndex, digit);
    }

    remaining ~/= 10;
    rodIndex -= 1;
  }

  return overlays;
}

List<MoveOverlay> addDigitOverlays(int rodIndex, int digit, List<RodState> rods) {
  final current = beadsToDigit(rods[rodIndex]);

  if (current + digit > 9) {
    return [
      ...addDigitOverlays(rodIndex - 1, 1, rods),
      ...subtractAmountOverlays(rodIndex, rods[rodIndex], 10 - digit),
    ];
  }

  if (!rods[rodIndex].heavenUp && rods[rodIndex].earthCount + digit > 4) {
    if (digit > 5) {
      final overlays = <MoveOverlay>[_heavenToBar(rodIndex)];

      for (var index = 0; index < digit - 5; index++) {
        overlays.add(_earthToBar(rodIndex));
      }

      return overlays;
    }

    return [
      _heavenToBar(rodIndex),
      ...subtractAmountOverlays(rodIndex, rods[rodIndex], 5 - digit),
    ];
  }

  return addAmountOverlays(rodIndex, rods[rodIndex], digit);
}

List<MoveOverlay> subtractDigitOverlays(
  int rodIndex,
  int digit,
  List<RodState> rods,
) {
  final current = beadsToDigit(rods[rodIndex]);

  if (current < digit) {
    return [
      ...subtractDigitOverlays(rodIndex - 1, 1, rods),
      ...addAmountOverlays(rodIndex, rods[rodIndex], 10 - digit),
    ];
  }

  return subtractAmountOverlays(rodIndex, rods[rodIndex], digit);
}

List<MoveOverlay> addAmountOverlays(int rodIndex, RodState state, int amount) {
  if (amount <= 0) {
    return const [];
  }

  final target = digitToBeads(beadsToDigit(state) + amount);
  final overlays = <MoveOverlay>[];

  if (!state.heavenUp && target.heavenUp) {
    overlays.add(_heavenToBar(rodIndex));
  }

  final earthToAdd =
      target.earthCount - (state.heavenUp && !target.heavenUp ? 0 : state.earthCount);

  for (var index = 0; index < earthToAdd; index++) {
    overlays.add(_earthToBar(rodIndex));
  }

  if (state.heavenUp && !target.heavenUp) {
    overlays.add(_heavenFromBar(rodIndex));
  }

  final earthToRemove = state.heavenUp && !target.heavenUp ? state.earthCount : 0;

  for (var index = 0; index < earthToRemove; index++) {
    overlays.add(_earthFromBar(rodIndex));
  }

  return overlays;
}

List<MoveOverlay> subtractAmountOverlays(
  int rodIndex,
  RodState state,
  int amount,
) {
  if (amount <= 0) {
    return const [];
  }

  final target = digitToBeads(beadsToDigit(state) - amount);
  final overlays = <MoveOverlay>[];

  if (state.heavenUp && !target.heavenUp) {
    overlays.add(_heavenFromBar(rodIndex));

    if (target.earthCount > 0) {
      for (var index = 0; index < target.earthCount; index++) {
        overlays.add(_earthToBar(rodIndex));
      }
    } else {
      for (var index = 0; index < state.earthCount; index++) {
        overlays.add(_earthFromBar(rodIndex));
      }
    }

    return overlays;
  }

  final earthToRemove = state.earthCount - target.earthCount;

  for (var index = 0; index < earthToRemove; index++) {
    overlays.add(_earthFromBar(rodIndex));
  }

  if (!state.heavenUp && target.heavenUp) {
    overlays.add(_heavenToBar(rodIndex));
  }

  final earthToAdd = target.earthCount - state.earthCount;

  if (earthToAdd > 0) {
    for (var index = 0; index < earthToAdd; index++) {
      overlays.add(_earthToBar(rodIndex));
    }
  }

  return overlays;
}

void applyAddDigit(List<RodState> rods, int rodIndex, int digit) {
  rods[rodIndex] = digitToBeads(beadsToDigit(rods[rodIndex]) + digit);
}

void applySubtractDigit(List<RodState> rods, int rodIndex, int digit) {
  rods[rodIndex] = digitToBeads(beadsToDigit(rods[rodIndex]) - digit);
}

MoveOverlay _earthToBar(int rodIndex) {
  return MoveOverlay(kind: MoveOverlayKind.earthToBar, rodIndex: rodIndex);
}

MoveOverlay _earthFromBar(int rodIndex) {
  return MoveOverlay(kind: MoveOverlayKind.earthFromBar, rodIndex: rodIndex);
}

MoveOverlay _heavenToBar(int rodIndex) {
  return MoveOverlay(kind: MoveOverlayKind.heavenToBar, rodIndex: rodIndex);
}

MoveOverlay _heavenFromBar(int rodIndex) {
  return MoveOverlay(kind: MoveOverlayKind.heavenFromBar, rodIndex: rodIndex);
}
