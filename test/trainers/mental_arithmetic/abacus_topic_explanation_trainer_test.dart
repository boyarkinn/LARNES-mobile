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
    expect(frames, hasLength(20));
    expect(
      frames.map((frame) => abacusToNumber(frame.rods)).toList(),
      simpleOneFrameValues,
    );
    expect(frames.every((frame) => frame.moves.single.rodIndex == 12), isTrue);
    expect(
      frames.every((frame) => frame.moves.single.hand == AbacusHand.right),
      isTrue,
    );
    expect(frames[0].moves.single.fingers, [AbacusFinger.thumb]);
    expect(frames[1].moves.single.fingers, [AbacusFinger.indexFinger]);
    expect(frames[11].rods.map(beadsToDigit).join(), '0000000000000');
    expect(frames.last.rods.map(beadsToDigit).join(), '0000000000000');
    expect(
      [
        for (var index = 0; index < frames.length; index++)
          if (frames[index].returnAfter) index,
      ],
      [1, 4, 7, 10, 11, 19],
    );
    expect(physicalGestureAudioKeys(plan), [
      simpleOneCue('intro'),
      simpleOneCue('add-one'),
      simpleOneCue('remove-one'),
      simpleOneCue('from-one'),
      simpleOneCue('example-minus-one'),
      simpleOneCue('from-two'),
      simpleOneCue('from-three'),
      simpleOneCue('example-intro'),
      simpleOneCue('example-plus-one'),
    ]);
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
      '0000000000000',
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
}
