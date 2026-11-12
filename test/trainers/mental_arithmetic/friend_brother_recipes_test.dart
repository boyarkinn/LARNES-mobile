import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/abacus_topic_explanation/friend_brother_recipes.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/physical_gesture_plan.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_model.dart';

const _filmedValues = <String, List<int>>{
  'friend-brother-6': [5, 11, 6, 12, 7, 13, 8, 14, 11, 5, 12, 6, 13, 7, 14, 8],
  'friend-brother-7': [5, 12, 6, 13, 7, 14, 12, 5, 13, 6, 14, 7],
  'friend-brother-8': [5, 13, 6, 14, 13, 5, 14, 6],
  'friend-brother-9': [5, 14, 5],
};

void main() {
  test(
    'four Friend + Brother lessons match the filmed cases and two-hand gestures',
    () {
      expect(friendBrotherLessonIds, [
        'friend-brother-6',
        'friend-brother-7',
        'friend-brother-8',
        'friend-brother-9',
      ]);
      for (final id in friendBrotherLessonIds) {
        final plan = friendBrotherPlans[id]!;
        final frames = compilePhysicalGesturePlan(plan);
        expect(plan.initialRods, hasLength(6), reason: id);
        expect(
          frames.map((frame) => abacusToNumber(frame.rods)).toList(),
          _filmedValues[id],
          reason: id,
        );
        expect(plan.steps.first, isA<NarrationGestureStep>(), reason: id);
        final gestures = frames
            .where((frame) => frame.moves.isNotEmpty)
            .toList();
        expect(gestures.length, (plan.steps.length - 1) ~/ 2, reason: id);
        for (final frame in gestures) {
          expect(frame.moves.map((move) => move.hand).toList(), [
            AbacusHand.left,
            AbacusHand.right,
          ], reason: id);
          expect(frame.moves.map((move) => move.rodIndex).toList(), [
            4,
            5,
          ], reason: id);
          expect(frame.moves.last.fingers, [
            AbacusFinger.thumb,
            AbacusFinger.indexFinger,
          ], reason: id);
          expect(frame.returnAfter, isTrue, reason: id);
        }
        expect(
          physicalGestureAudioKeys(plan),
          isNot(contains('explanation:abacus-topic:simple-1:example-intro')),
          reason: id,
        );
      }
    },
  );
}
