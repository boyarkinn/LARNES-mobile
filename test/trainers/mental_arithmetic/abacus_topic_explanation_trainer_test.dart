import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/abacus_topic_explanation/abacus_topic_explanation_trainer.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/abacus_topic_explanation/recipes.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/abacus_hand_layer.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/physical_gesture_abacus.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/physical_gesture_example.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/physical_gesture_plan.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/physical_gesture_playback.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_model.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_widget.dart';

void main() {
  test('simple one matches the filmed bases and final example', () {
    final plan = topicExplanationRecipe('simple-1');
    final frames = compilePhysicalGesturePlan(plan);
    expect(plan.initialRods, hasLength(6));
    expect(frames, hasLength(20));
    expect(frames.every((frame) => frame.rods.length == 6), isTrue);
    expect(
      frames.map((frame) => abacusToNumber(frame.rods)).toList(),
      simpleOneFrameValues,
    );
    expect(
      [
        for (var index = 0; index < frames.length; index++)
          if (frames[index].moves.isEmpty) index,
      ],
      [2, 5, 8, 11],
    );
    expect(
      frames
          .where((frame) => frame.moves.isNotEmpty)
          .every((frame) => frame.moves.single.rodIndex == 5),
      isTrue,
    );
    expect(
      frames
          .where((frame) => frame.moves.isNotEmpty)
          .every((frame) => frame.moves.single.hand == AbacusHand.right),
      isTrue,
    );
    expect(frames[0].moves.single.fingers, [AbacusFinger.thumb]);
    expect(frames[1].moves.single.fingers, [AbacusFinger.indexFinger]);
    expect(frames[11].rods.map(beadsToDigit).join(), '000000');
    expect(plan.steps.whereType<SetupGestureStep>(), hasLength(4));
    final reset = plan.steps.whereType<SetupGestureStep>().last;
    expect(reset.audioKey, isNull);
    expect(reset.pauseAfterMs, 450);
    expect(frames.last.rods.map(beadsToDigit).join(), '000000');
    expect(
      [
        for (var index = 0; index < frames.length; index++)
          if (frames[index].returnAfter) index,
      ],
      [0, 1, 3, 4, 6, 7, 9, 10, 19],
    );
    expect(physicalGestureAudioKeys(plan), [
      simpleOneCue('intro'),
      simpleOneCue('add-one'),
      simpleOneCue('example-plus-one'),
      simpleOneCue('remove-one'),
      simpleOneCue('example-minus-one'),
      simpleOneCue('from-one'),
      simpleOneCue('from-two'),
      simpleOneCue('from-three'),
      simpleOneCue('example-intro'),
    ]);
    for (final (explanation, action) in [
      ('add-one', 'example-plus-one'),
      ('remove-one', 'example-minus-one'),
      ('from-one', 'example-plus-one'),
      ('from-two', 'example-plus-one'),
      ('from-three', 'example-plus-one'),
    ]) {
      final index = plan.steps.indexWhere(
        (step) => step.audioKey == simpleOneCue(explanation),
      );
      expect(index, greaterThanOrEqualTo(0));
      if (explanation.startsWith('from-')) {
        final setup = plan.steps[index] as SetupGestureStep;
        expect(setup.audioMode, PhysicalGestureAudioMode.parallel);
        expect(setup.changes.single.rodIndex, simpleOneRodIndex);
      } else {
        expect(plan.steps[index], isA<NarrationGestureStep>());
      }
      final movement = plan.steps[index + 1] as GroupGestureStep;
      expect(movement.audioKey, simpleOneCue(action));
      expect(movement.audioMode, PhysicalGestureAudioMode.parallel);
    }
    validatePhysicalGestureExample(plan, [
      const PhysicalGestureCheckpoint(afterFrame: 0, value: 0),
      const PhysicalGestureCheckpoint(afterFrame: 20, value: 0),
    ]);
  });

  testWidgets('lesson starts on the shared scene without text or controls', (
    tester,
  ) async {
    var completions = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AbacusTopicExplanationTrainer(
            params: const {'lessonId': 'simple-1', 'speed': 'fast'},
            onComplete: () => completions++,
          ),
        ),
      ),
    );

    expect(find.byType(PhysicalGestureAbacus), findsOneWidget);
    expect(
      tester
          .widget<PhysicalGestureAbacus>(find.byType(PhysicalGestureAbacus))
          .autoPlay,
      isTrue,
    );
    expect(find.byType(AbacusWidget), findsOneWidget);
    expect(find.byType(AbacusHandLayer), findsOneWidget);
    expect(
      tester
          .widget<AbacusWidget>(find.byType(AbacusWidget))
          .rods
          .map(beadsToDigit)
          .join(),
      '000000',
    );
    expect(find.byType(Text), findsNothing);
    expect(find.byType(TextButton), findsNothing);
    expect(find.byType(ElevatedButton), findsNothing);
    expect(completions, 0);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  test('full recipe completes once after its last movement', () {
    fakeAsync((clock) {
      var completions = 0;
      final values = <int>[];
      final player = PhysicalGesturePlayer(
        plan: topicExplanationRecipe('simple-1'),
        speed: PhysicalGestureSpeed.fast,
        reducedMotion: true,
        onFrame: (frame, _) => values.add(abacusToNumber(frame.rods)),
        onCue: (_, _) async {},
        onComplete: () => completions++,
        nowMs: () => clock.elapsed.inMilliseconds,
      );
      player.play();
      clock.flushMicrotasks();
      clock.elapse(const Duration(seconds: 30));
      clock.flushMicrotasks();
      expect(values, simpleOneFrameValues);
      expect(completions, 1);
      clock.elapse(const Duration(seconds: 3));
      expect(completions, 1);
    });
  });

  test('the explanatory cue finishes before the short spoken movement', () {
    fakeAsync((clock) {
      final explanation = Completer<void>();
      final events = <String>[];
      final player = PhysicalGesturePlayer(
        plan: topicExplanationRecipe('simple-1'),
        speed: PhysicalGestureSpeed.medium,
        reducedMotion: true,
        onFrame: (_, index) => events.add('frame:$index'),
        onCue: (key, _) {
          events.add(key);
          return key == simpleOneCue('add-one')
              ? explanation.future
              : Future<void>.value();
        },
        nowMs: () => clock.elapsed.inMilliseconds,
      );
      player.play();
      clock.flushMicrotasks();
      expect(events, [simpleOneCue('intro'), simpleOneCue('add-one')]);
      clock.elapse(const Duration(seconds: 2));
      expect(events, [simpleOneCue('intro'), simpleOneCue('add-one')]);
      explanation.complete();
      clock.flushMicrotasks();
      clock.elapse(const Duration(milliseconds: 100));
      expect(events.take(4), [
        simpleOneCue('intro'),
        simpleOneCue('add-one'),
        simpleOneCue('example-plus-one'),
        'frame:0',
      ]);
      player.cancel();
    });
  });

  test('all three speeds finish the narrated lesson exactly once', () {
    final completionTimes = <PhysicalGestureSpeed, int>{};
    for (final speed in PhysicalGestureSpeed.values) {
      fakeAsync((clock) {
        var completions = 0;
        final values = <int>[];
        final cues = <String>[];
        final player = PhysicalGesturePlayer(
          plan: topicExplanationRecipe('simple-1'),
          speed: speed,
          onFrame: (frame, _) => values.add(abacusToNumber(frame.rods)),
          onCue: (key, _) {
            cues.add(key);
            return Future<void>.delayed(const Duration(milliseconds: 500));
          },
          onComplete: () {
            completions++;
            completionTimes[speed] = clock.elapsed.inMilliseconds;
          },
          nowMs: () => clock.elapsed.inMilliseconds,
        );
        player.play();
        clock.elapse(const Duration(seconds: 60));
        clock.flushMicrotasks();
        expect(values, simpleOneFrameValues);
        expect(cues, hasLength(23));
        expect(
          cues.toSet(),
          physicalGestureAudioKeys(topicExplanationRecipe('simple-1')).toSet(),
        );
        expect(completions, 1);
        player.cancel();
      });
    }
    expect(
      completionTimes[PhysicalGestureSpeed.slow]!,
      greaterThan(completionTimes[PhysicalGestureSpeed.medium]!),
    );
    expect(
      completionTimes[PhysicalGestureSpeed.medium]!,
      greaterThan(completionTimes[PhysicalGestureSpeed.fast]!),
    );
  });

  test('closing mid-speech does not finish; a fresh launch starts at zero', () {
    fakeAsync((clock) {
      final firstCue = Completer<void>();
      var completions = 0;
      final interrupted = PhysicalGesturePlayer(
        plan: topicExplanationRecipe('simple-1'),
        speed: PhysicalGestureSpeed.medium,
        onFrame: (_, _) => fail('No bead should move before the first cue'),
        onCue: (_, _) => firstCue.future,
        onComplete: () => completions++,
        nowMs: () => clock.elapsed.inMilliseconds,
      );
      interrupted.play();
      interrupted.cancel();
      firstCue.complete();
      clock.flushMicrotasks();
      clock.elapse(const Duration(seconds: 60));
      expect(completions, 0);

      final values = <int>[];
      final restarted = PhysicalGesturePlayer(
        plan: topicExplanationRecipe('simple-1'),
        speed: PhysicalGestureSpeed.medium,
        onFrame: (frame, _) => values.add(abacusToNumber(frame.rods)),
        onCue: (_, _) async {},
        onComplete: () => completions++,
        nowMs: () => clock.elapsed.inMilliseconds,
      );
      restarted.play();
      clock.flushMicrotasks();
      clock.elapse(const Duration(seconds: 40));
      clock.flushMicrotasks();
      expect(values, simpleOneFrameValues);
      expect(completions, 1);
      restarted.cancel();
    });
  });

  testWidgets('the abacus and both hands fit narrow portrait and landscape', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    for (final size in [const Size(360, 640), const Size(640, 360)]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AbacusTopicExplanationTrainer(
              params: const {'lessonId': 'simple-1', 'speed': 'medium'},
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(AbacusHandLayer), findsOneWidget);
      final scene = tester.getRect(find.byType(PhysicalGestureAbacus));
      final abacus = tester.getRect(find.byType(AbacusWidget));
      expect(scene.size, size);
      expect(abacus.left, greaterThanOrEqualTo(0));
      expect(abacus.right, lessThanOrEqualTo(size.width));
      expect(abacus.top, greaterThanOrEqualTo(0));
      expect(abacus.bottom, lessThanOrEqualTo(size.height));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }
  });
}
