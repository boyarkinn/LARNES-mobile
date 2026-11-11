import 'package:larnes_mobile/trainers/mental_arithmetic/shared/physical_gesture_plan.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_model.dart';

class PhysicalGestureCheckpoint {
  const PhysicalGestureCheckpoint({
    required this.afterFrame,
    required this.value,
  });

  /// Zero checks the initial abacus; N checks the state after frame N.
  final int afterFrame;
  final int value;
}

/// Checks the teaching script against the same abacus model used by playback.
///
/// A recipe declares its intended results explicitly. No exercise-local
/// arithmetic logic needs to infer a number from the spoken text.
void validatePhysicalGestureExample(
  PhysicalGesturePlan plan,
  List<PhysicalGestureCheckpoint> checkpoints,
) {
  final frames = compilePhysicalGesturePlan(plan);
  var previousFrame = -1;
  for (final checkpoint in checkpoints) {
    if (checkpoint.afterFrame < 0 || checkpoint.afterFrame > frames.length) {
      throw RangeError.range(
        checkpoint.afterFrame,
        0,
        frames.length,
        'afterFrame',
      );
    }
    if (checkpoint.afterFrame <= previousFrame) {
      throw StateError(
        'Контрольные точки должны идти по порядку без повторов.',
      );
    }
    previousFrame = checkpoint.afterFrame;
    final rods = checkpoint.afterFrame == 0
        ? plan.initialRods
        : frames[checkpoint.afterFrame - 1].rods;
    final actual = abacusToNumber(rods);
    if (actual != checkpoint.value) {
      throw StateError(
        'После кадра ${checkpoint.afterFrame} на абакусе $actual, '
        'ожидалось ${checkpoint.value}.',
      );
    }
  }
}
