import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/abacus_hand_motion.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/physical_gesture_plan.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_model.dart';

void main() {
  test('thumb movement selects the fist and follows a lower bead', () {
    const before = RodState(heavenUp: false, earthCount: 0);
    const after = RodState(heavenUp: false, earthCount: 1);
    const frame = PhysicalGestureFrame(
      rods: [after],
      moves: [
        PhysicalBeadMove(
          rodIndex: 0,
          to: after,
          hand: AbacusHand.right,
          fingers: [AbacusFinger.thumb],
        ),
      ],
      pauseAfterMs: 0,
    );
    final motion = handMotionsForFrame([before], frame).single;
    expect(motion.pose, AbacusHandPose.fist);
    expect(motion.thumb, isNotNull);
    expect(motion.index, isNull);
    expect(motion.thumb!.end.dy, lessThan(motion.thumb!.start.dy));
    expect(
      handRigAt(motion, 0).origin.dy,
      isNot(handRigAt(motion, 1).origin.dy),
    );
  });

  test('left index movement contacts the opposite bead edge', () {
    const before = RodState(heavenUp: false, earthCount: 0);
    const after = RodState(heavenUp: true, earthCount: 0);
    PhysicalGestureFrame frame(AbacusHand hand) => PhysicalGestureFrame(
      rods: [after],
      moves: [
        PhysicalBeadMove(
          rodIndex: 0,
          to: after,
          hand: hand,
          fingers: [AbacusFinger.indexFinger],
        ),
      ],
      pauseAfterMs: 0,
    );
    final left = handMotionsForFrame([before], frame(AbacusHand.left)).single;
    final right = handMotionsForFrame([before], frame(AbacusHand.right)).single;
    expect(left.pose, AbacusHandPose.indexOnly);
    expect(left.index, isNotNull);
    expect(left.thumb, isNull);
    expect(left.index!.start.dx, lessThan(right.index!.start.dx));
  });

}
