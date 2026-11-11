import 'package:larnes_mobile/trainers/mental_arithmetic/shared/physical_gesture_plan.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_model.dart';

/// Select working fingers from the physical bead transition, independent of lesson.
List<AbacusFinger> fingersForPhysicalRodTransition(RodState from, RodState to) {
  if (from.heavenUp != to.heavenUp && from.earthCount != to.earthCount) {
    return const [AbacusFinger.thumb, AbacusFinger.indexFinger];
  }
  if (from.heavenUp != to.heavenUp) return const [AbacusFinger.indexFinger];
  return [
    to.earthCount > from.earthCount
        ? AbacusFinger.thumb
        : AbacusFinger.indexFinger,
  ];
}
