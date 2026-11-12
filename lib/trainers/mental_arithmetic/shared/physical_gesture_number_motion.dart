import 'package:larnes_mobile/trainers/mental_arithmetic/shared/physical_gesture_fingers.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/physical_gesture_plan.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_model.dart';

class PhysicalNumberSetup {
  const PhysicalNumberSetup(this.rods, this.changes);
  final List<RodState> rods;
  final List<BeadOnlyMove> changes;
}

class PhysicalNumberMotion {
  const PhysicalNumberMotion(this.rods, this.frames, this.values);
  final List<RodState> rods;
  final List<List<PhysicalBeadMove>> frames;
  final List<int> values;
}

PhysicalNumberSetup physicalNumberSetup(List<RodState> from, int value) {
  final rods = numberToAbacus(value, from.length);
  final changes = <BeadOnlyMove>[];
  for (var index = 0; index < rods.length; index++) {
    if (rods[index] != from[index]) {
      changes.add(BeadOnlyMove(rodIndex: index, to: rods[index]));
    }
  }
  return PhysicalNumberSetup(rods, changes);
}

/// Two hands share a frame; each hand touches one rod at a time.
PhysicalNumberMotion physicalNumberMotion(List<RodState> from, int value) {
  final rods = numberToAbacus(value, from.length);
  final left = <PhysicalBeadMove>[];
  final right = <PhysicalBeadMove>[];
  for (var index = 0; index < rods.length; index++) {
    final before = from[index];
    final to = rods[index];
    if (before == to) continue;
    final hand = index == rods.length - 1 ? AbacusHand.right : AbacusHand.left;
    final move = PhysicalBeadMove(
      rodIndex: index,
      to: to,
      hand: hand,
      fingers: fingersForPhysicalRodTransition(before, to),
    );
    (hand == AbacusHand.left ? left : right).add(move);
  }
  final frames = <List<PhysicalBeadMove>>[];
  final values = <int>[];
  final current = [...from];
  while (left.isNotEmpty || right.isNotEmpty) {
    final moves = <PhysicalBeadMove>[];
    if (left.isNotEmpty) moves.add(left.removeAt(0));
    if (right.isNotEmpty) moves.add(right.removeAt(0));
    frames.add(moves);
    for (final move in moves) {
      current[move.rodIndex] = move.to;
    }
    values.add(abacusToNumber(current));
  }
  return PhysicalNumberMotion(rods, frames, values);
}
