import 'package:larnes_mobile/trainers/math/apple_count_show/apple_count_show_geometry.dart';

const appleDropStaggerMs = 300;
const appleFlightDurationMs = 580;

class AppleMotionStep {
  const AppleMotionStep({
    required this.appleIndex,
    required this.delayMs,
    required this.from,
    required this.to,
  });

  final int appleIndex;
  final int delayMs;
  final ScenePoint from;
  final ScenePoint to;
}

List<AppleMotionStep> buildAppleDropSequence(int appleCount) {
  final slots = getAppleSlotPositions(appleCount);

  return List.generate(slots.length, (appleIndex) {
    return AppleMotionStep(
      appleIndex: appleIndex,
      delayMs: appleIndex * appleDropStaggerMs,
      from: getAppleSpawnPoint(appleIndex, appleCount),
      to: slots[appleIndex],
    );
  });
}

int appleDropTotalDurationMs(int appleCount) {
  if (appleCount <= 0) {
    return 0;
  }
  return (appleCount - 1) * appleDropStaggerMs + appleFlightDurationMs;
}
