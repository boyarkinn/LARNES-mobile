import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/abacus_topic_explanation/simple_multi_recipes.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/physical_gesture_plan.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/physical_gesture_playback.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_model.dart';

void main() {
  const filmedExampleValues = <String, List<int>>{
    'simple-tens': [20, 90, 10, 70, 90, 0],
    'simple-11-19': [11, 19, 0, 14, 1, 16],
    'simple-44': [22, 11, 44, 0, 42],
    'simple-55': [44, 99, 66, 55, 0, 45],
    'simple-66': [66, 11, 77, 99, 33],
    'simple-77': [77, 88, 11, 84, 10],
    'simple-88': [10, 98, 10, 44, 0],
    'simple-99': [44, 99, 0, 99],
    'simple-hundreds': [100, 900, 0, 700, 100, 900],
    'simple-000': [596, 55, 499, 113],
  };

  test('all ten multi-digit lessons preserve filmed example values', () {
    expect(simpleMultiLessonIds, hasLength(10));
    for (final id in simpleMultiLessonIds) {
      final recipe = simpleMultiRecipes[id]!;
      final plan = simpleMultiPlans[id]!;
      final frames = compilePhysicalGesturePlan(plan);
      expect(identical(plan, recipe.plan), isTrue, reason: id);
      expect(plan.initialRods, hasLength(6), reason: id);
      expect(recipe.exampleValues, filmedExampleValues[id], reason: id);
      expect(
        abacusToNumber(frames.last.rods),
        filmedExampleValues[id]!.last,
        reason: id,
      );
      expect(physicalGestureAudioKeys(plan), recipe.audioKeys, reason: id);
      expect(frames.last.returnAfter, isTrue, reason: id);
      for (final frame in frames) {
        expect(frame.rods, hasLength(6), reason: id);
        expect(
          frame.moves.map((move) => move.hand).toSet().length,
          frame.moves.length,
          reason: 'One rod per hand in $id',
        );
        for (final move in frame.moves) {
          expect(
            move.hand,
            move.rodIndex == 5 ? AbacusHand.right : AbacusHand.left,
            reason: id,
          );
        }
      }
    }
  });

  test(
    'base variants park both hands and two-hand lessons coordinate gestures',
    () {
      for (final id in ['simple-66', 'simple-77', 'simple-88']) {
        final frames = compilePhysicalGesturePlan(simpleMultiPlans[id]!);
        expect(frames.any((frame) => frame.moves.isEmpty), isTrue, reason: id);
      }
      for (final id in [
        'simple-11-19',
        'simple-44',
        'simple-55',
        'simple-66',
        'simple-77',
        'simple-88',
        'simple-99',
        'simple-000',
      ]) {
        final frames = compilePhysicalGesturePlan(simpleMultiPlans[id]!);
        expect(
          frames.any(
            (frame) =>
                frame.moves.any((move) => move.hand == AbacusHand.left) &&
                frame.moves.any((move) => move.hand == AbacusHand.right),
          ),
          isTrue,
          reason: id,
        );
      }
      final triple = compilePhysicalGesturePlan(
        simpleMultiPlans['simple-000']!,
      );
      for (final rod in [3, 4, 5]) {
        expect(
          triple.any(
            (frame) => frame.moves.any((move) => move.rodIndex == rod),
          ),
          isTrue,
          reason: 'rod $rod',
        );
      }
    },
  );

  test(
    'spoken +596 stays parallel to both frames of the three-rod gesture',
    () {
      fakeAsync((clock) {
        final source = simpleMultiPlans['simple-000']!;
        final series = source.steps.whereType<SeriesGestureStep>().first;
        expect(series.frames, hasLength(2));
        expect(series.audioKey, 'explanation:abacus-topic:action:plus-596');
        final speech = Completer<void>();
        final seen = <String>[];
        final player = PhysicalGesturePlayer(
          plan: PhysicalGesturePlan(
            initialRods: source.initialRods,
            steps: [
              series,
              const NarrationGestureStep(audioKey: 'after'),
            ],
            beadTransitionMs: source.beadTransitionMs,
          ),
          speed: PhysicalGestureSpeed.medium,
          onFrame: (frame, _) =>
              seen.add('frame:${abacusToNumber(frame.rods)}'),
          onCue: (key, _) {
            seen.add('cue:$key');
            return key == series.audioKey
                ? speech.future
                : Future<void>.value();
          },
          nowMs: () => clock.elapsed.inMilliseconds,
        );
        player.play();
        clock.flushMicrotasks();
        expect(seen, contains('frame:506'));
        clock.elapse(const Duration(seconds: 2));
        clock.flushMicrotasks();
        expect(seen, contains('frame:596'));
        expect(seen, isNot(contains('cue:after')));
        speech.complete();
        clock.flushMicrotasks();
        expect(seen, contains('cue:after'));
        player.cancel();
      });
    },
  );
}
