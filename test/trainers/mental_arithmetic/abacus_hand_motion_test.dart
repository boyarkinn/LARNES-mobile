import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/abacus_hand_motion.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/physical_gesture_plan.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_geometry.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_model.dart';

void main() {
  test('parked hands occupy distinct positions below the abacus', () {
    final box = abacusViewBox(13);
    final left = handRestOrigin(AbacusHand.left, box.width, box.height);
    final right = handRestOrigin(AbacusHand.right, box.width, box.height);
    expect(
      left.dx + handArtboardSize.width * handParkScale / 2,
      closeTo(box.width * 0.24, 0.001),
    );
    expect(
      right.dx + handArtboardSize.width * handParkScale / 2,
      closeTo(box.width * 0.76, 0.001),
    );
    expect(left.dy, closeTo(box.height - 27, 0.001));
    expect(right.dy, left.dy);
    final leftImage = handIdleImageRect(AbacusHand.left, box.width, box.height);
    final rightImage = handIdleImageRect(
      AbacusHand.right,
      box.width,
      box.height,
    );
    expect(leftImage.center.dx, closeTo(box.width * 0.24, 0.001));
    expect(rightImage.center.dx, closeTo(box.width * 0.76, 0.001));
    expect(leftImage.top, greaterThan(box.height - 27));
  });

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
