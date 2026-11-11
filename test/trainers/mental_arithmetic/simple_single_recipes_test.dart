import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/abacus_topic_explanation/simple_single_recipes.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/physical_gesture_plan.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_model.dart';

// Source-video states, including the frame-checked rapid endings of 7 and 8.
const _expected = <String, List<int>>{
  'simple-2': [2, 0, 2, 0, 1, 3, 1, 2, 4, 2, 0, 1, 3, 1, 3, 1],
  'simple-3': [3, 0, 3, 0, 1, 4, 1, 0, 1, 4, 1, 4, 1],
  'simple-4': [4, 0, 4, 0, 4],
  'simple-5': [5, 0, 5, 6, 1, 0, 5],
  'simple-6': [6, 0, 1, 7, 1, 2, 8, 2, 3, 9, 3, 0, 1, 7, 9, 3],
  'simple-7': [7, 0, 1, 8, 1, 2, 9, 2, 0, 7, 9, 2, 0],
  'simple-8': [8, 0, 1, 9, 1, 0, 8, 0, 1, 9, 1],
  'simple-9': [9, 0, 9, 0, 9, 0, 9, 0],
};

void main() {
  test('all eight single-digit lessons reproduce their source bead states', () {
    expect(simpleSingleLessonIds, _expected.keys.toList());
    for (final id in simpleSingleLessonIds) {
      final plan = simpleSinglePlans[id]!;
      expect(plan.initialRods.length, 6, reason: id);
      final frames = compilePhysicalGesturePlan(plan);
      expect(
        frames.map((frame) => beadsToDigit(frame.rods[5])).toList(),
        _expected[id],
        reason: id,
      );
      expect(frames.last.returnAfter, isTrue, reason: id);
      expect(
        physicalGestureAudioKeys(plan),
        contains('explanation:abacus-topic:$id:answer-${_expected[id]!.last}'),
        reason: id,
      );
    }
  });

  test(
    'setups have no hand; isolated demonstrations return before example',
    () {
      const expectedSetups = <String, int>{
        'simple-2': 3,
        'simple-3': 2,
        'simple-4': 0,
        'simple-5': 0,
        'simple-6': 4,
        'simple-7': 3,
        'simple-8': 2,
        'simple-9': 0,
      };
      for (final id in simpleSingleLessonIds) {
        final plan = simpleSinglePlans[id]!;
        final frames = compilePhysicalGesturePlan(plan);
        final setups = frames.where((frame) => frame.moves.isEmpty).toList();
        expect(setups.length, expectedSetups[id], reason: id);
        expect(setups.every((frame) => !frame.returnAfter), isTrue, reason: id);
        final exampleIndex = plan.steps.indexWhere(
          (step) =>
              step.audioKey ==
              'explanation:abacus-topic:simple-1:example-intro',
        );
        expect(exampleIndex, greaterThanOrEqualTo(0), reason: id);
        final before = plan.steps
            .take(exampleIndex)
            .whereType<GroupGestureStep>();
        expect(before.every((step) => step.returnAfter), isTrue, reason: id);
        final after = plan.steps
            .skip(exampleIndex + 1)
            .whereType<GroupGestureStep>()
            .toList();
        expect(
          after.take(after.length - 1).every((step) => !step.returnAfter),
          isTrue,
          reason: id,
        );
        expect(after.last.returnAfter, isTrue, reason: id);
      }
    },
  );

  test('heaven and crab lessons use the observed working fingers', () {
    final five = compilePhysicalGesturePlan(simpleSinglePlans['simple-5']!);
    expect(five[0].moves[0].fingers, [AbacusFinger.indexFinger]);
    expect(five[1].moves[0].fingers, [AbacusFinger.indexFinger]);
    for (final id in ['simple-6', 'simple-7', 'simple-8', 'simple-9']) {
      final frames = compilePhysicalGesturePlan(simpleSinglePlans[id]!);
      expect(frames[0].moves[0].fingers, [
        AbacusFinger.thumb,
        AbacusFinger.indexFinger,
      ], reason: id);
      expect(frames[1].moves[0].fingers, [
        AbacusFinger.thumb,
        AbacusFinger.indexFinger,
      ], reason: id);
    }
  });
}
