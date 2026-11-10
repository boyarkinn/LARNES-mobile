import 'package:larnes_mobile/trainers/mental_arithmetic/shared/abacus_playback_plan.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_model.dart';
import 'package:larnes_mobile/trainers/shared/abacus/moving_bead_highlights.dart';

class AbacusGestureView {
  const AbacusGestureView({
    required this.rods,
    required this.highlights,
    required this.isDone,
  });

  final List<RodState> rods;
  final List<RodMovingBeadHighlight>? highlights;
  final bool isDone;
}

/// The frame after [position] physical gestures, including movement colors.
AbacusGestureView abacusGestureView(
  AbacusPlaybackPlan plan,
  int totalRods,
  int position,
) {
  if (position < 0 || position > plan.gestures.length) {
    throw RangeError.range(position, 0, plan.gestures.length, 'position');
  }
  final initial = numberToAbacus(0, totalRods);
  final movement = position > 0 ? plan.gestures[position - 1] : null;
  final rods = movement?.rods ?? initial;
  final before = position > 1 ? plan.gestures[position - 2].rods : initial;
  return AbacusGestureView(
    rods: List.of(rods),
    highlights: movement == null
        ? null
        : resolveMovingBeadHighlights(before, rods),
    isDone: position == plan.gestures.length,
  );
}
