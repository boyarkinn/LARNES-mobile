import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/abacus_topic_explanation/brother_recipes.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/physical_gesture_plan.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_model.dart';

const _filmedValues = <String, List<int>>{
  'brother-4': [5, 1, 5, 6, 2, 6, 7, 3, 7, 8, 4, 8, 0, 5, 1, 7, 3, 7, 0],
  'brother-3': [5, 2, 5, 6, 3, 6, 7, 4, 7, 0, 5, 2, 8, 5, 2, 5],
  'brother-2': [5, 3, 5, 6, 4, 6, 0, 5, 3, 5, 6, 4],
  'brother-1': [5, 4, 5, 0, 5, 4, 5, 4],
};

void main() {
  test('four Brother lessons preserve source beads and use right hand', () {
    expect(brotherLessonIds, [
      'brother-4',
      'brother-3',
      'brother-2',
      'brother-1',
    ]);
    for (final id in brotherLessonIds) {
      final plan = brotherPlans[id]!;
      final frames = compilePhysicalGesturePlan(plan);
      expect(plan.initialRods, hasLength(6), reason: id);
      expect(
        frames.map((frame) => beadsToDigit(frame.rods[5])).toList(),
        _filmedValues[id],
        reason: id,
      );
      expect(frames.last.returnAfter, isTrue, reason: id);
      expect(
        frames.every(
          (frame) => frame.moves.every(
            (move) => move.hand == AbacusHand.right && move.rodIndex == 5,
          ),
        ),
        isTrue,
        reason: id,
      );
      expect(
        frames.any(
          (frame) => frame.moves.any(
            (move) =>
                move.fingers.length == 2 &&
                move.fingers.contains(AbacusFinger.thumb) &&
                move.fingers.contains(AbacusFinger.indexFinger),
          ),
        ),
        isTrue,
        reason: id,
      );
      final exampleIntro = plan.steps.indexWhere(
        (step) =>
            step.audioKey == 'explanation:abacus-topic:simple-1:example-intro',
      );
      expect(exampleIntro, greaterThanOrEqualTo(0), reason: id);
      expect(
        plan.steps
            .take(exampleIntro)
            .whereType<GroupGestureStep>()
            .every((step) => step.returnAfter),
        isTrue,
        reason: id,
      );
      final example = plan.steps
          .skip(exampleIntro + 1)
          .whereType<GroupGestureStep>()
          .toList();
      expect(
        example.take(example.length - 1).every((step) => !step.returnAfter),
        isTrue,
        reason: id,
      );
      expect(example.last.returnAfter, isTrue, reason: id);
      expect(
        plan.steps.any(
          (step) =>
              step is SetupGestureStep &&
              step.audioKey?.endsWith(':subtract') == true,
        ),
        isTrue,
        reason: id,
      );
      expect(
        physicalGestureAudioKeys(plan).last,
        'explanation:abacus-topic:$id:answer-${_filmedValues[id]!.last}',
        reason: id,
      );
    }
  });
}
