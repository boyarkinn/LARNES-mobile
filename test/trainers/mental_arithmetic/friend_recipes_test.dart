import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/abacus_topic_explanation/friend_recipes.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/physical_gesture_plan.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_model.dart';

const _filmedValues = <String, List<int>>{
  'friend-9': [10, 1, 10, 1, 10, 1, 10, 0, 10, 1, 7, 16],
  'friend-8': [10, 2, 10, 2, 10, 2, 10, 0, 1, 9, 17, 9],
  'friend-7': [10, 3, 10, 3, 10, 3, 10, 0, 10, 3, 9, 16],
  'friend-6': [10, 4, 10, 4, 10, 4, 10, 0, 10, 4, 9, 15],
  'friend-5': [10, 5, 10, 5, 10, 5, 10, 0, 10, 5, 9, 14],
  'friend-4': [
    10,
    6,
    10,
    6,
    10,
    11,
    7,
    11,
    12,
    8,
    12,
    13,
    9,
    13,
    0,
    7,
    11,
    19,
    13,
    9,
  ],
  'friend-3': [10, 7, 10, 7, 10, 11, 8, 11, 12, 9, 12, 0, 7, 10, 12, 11, 8],
  'friend-2': [10, 8, 10, 8, 10, 11, 9, 11, 0, 9, 11, 8, 2, 11, 9],
  'friend-1': [10, 9, 10, 9, 10, 9, 10, 0, 9, 10, 6, 9, 10, 9],
};

void main() {
  test(
    'nine Friend lessons follow filmed values and move two hands together',
    () {
      expect(friendLessonIds, [
        'friend-9',
        'friend-8',
        'friend-7',
        'friend-6',
        'friend-5',
        'friend-4',
        'friend-3',
        'friend-2',
        'friend-1',
      ]);
      for (final id in friendLessonIds) {
        final plan = friendPlans[id]!;
        final frames = compilePhysicalGesturePlan(plan);
        expect(plan.initialRods, hasLength(6), reason: id);
        expect(
          frames.map((frame) => abacusToNumber(frame.rods)).toList(),
          _filmedValues[id],
          reason: id,
        );
        expect(frames.last.returnAfter, isTrue, reason: id);
        expect(frames[1].moves.map((move) => move.hand).toList(), [
          AbacusHand.left,
          AbacusHand.right,
        ], reason: id);
        expect(frames[1].moves.map((move) => move.rodIndex).toList(), [
          4,
          5,
        ], reason: id);
        final amount = int.parse(id.substring('friend-'.length));
        final subtractRight = amount >= 6
            ? [AbacusFinger.thumb]
            : amount == 5
            ? [AbacusFinger.indexFinger]
            : [AbacusFinger.thumb, AbacusFinger.indexFinger];
        final addRight = amount >= 5
            ? [AbacusFinger.indexFinger]
            : [AbacusFinger.thumb, AbacusFinger.indexFinger];
        expect(frames[1].moves.map((move) => move.fingers).toList(), [
          [AbacusFinger.indexFinger],
          subtractRight,
        ], reason: id);
        expect(frames[2].moves.map((move) => move.fingers).toList(), [
          [AbacusFinger.thumb],
          addRight,
        ], reason: id);
        expect(
          frames.every(
            (frame) =>
                frame.moves.map((move) => move.hand).toSet().length ==
                frame.moves.length,
          ),
          isTrue,
          reason: id,
        );
        final intro = plan.steps.indexWhere(
          (step) => step.audioKey == _exampleIntro,
        );
        expect(intro, greaterThanOrEqualTo(0), reason: id);
        final teaching = plan.steps
            .take(intro)
            .where(
              (step) => step is GroupGestureStep || step is SeriesGestureStep,
            );
        expect(teaching.every((step) => step.returnAfter), isTrue, reason: id);
        final example = plan.steps
            .skip(intro + 1)
            .where(
              (step) => step is GroupGestureStep || step is SeriesGestureStep,
            )
            .toList();
        expect(
          example.take(example.length - 1).every((step) => !step.returnAfter),
          isTrue,
          reason: id,
        );
        expect(example.last.returnAfter, isTrue, reason: id);
      }
    },
  );
}

const _exampleIntro = 'explanation:abacus-topic:simple-1:example-intro';
