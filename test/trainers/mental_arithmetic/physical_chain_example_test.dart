import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/audio/speech_bank.dart';
import 'package:larnes_mobile/trainers/audio/catalog_playback_failure.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/generate.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/topics.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/types.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/physical_chain_example.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/physical_chain_example_widget.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/physical_example_cues.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/physical_gesture_plan.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/physical_gesture_playback.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_model.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_widget.dart';
import 'package:larnes_mobile/trainers/shared/instruction/trainer_instruction_scene.dart';

Chain _chain() => const Chain(
  answer: 1,
  intermediates: [0, 250, 1],
  topicId: 'simple-1',
  steps: [
    ChainStep(amount: 250, sign: '+'),
    ChainStep(amount: 249, sign: '-'),
  ],
);

PhysicalBeadMove _move(int value) => PhysicalBeadMove(
  rodIndex: 0,
  to: digitToBeads(value),
  hand: AbacusHand.right,
  fingers: const [AbacusFinger.thumb],
);

PhysicalGesturePlan _timed({
  bool series = false,
  String? cue,
  int minimum = 3000,
}) => PhysicalGesturePlan(
  initialRods: [digitToBeads(0)],
  beadTransitionMs: 400,
  steps: [
    if (series)
      SeriesGestureStep(
        frames: [
          [_move(1)],
          [_move(2)],
          [_move(3)],
        ],
        pauseAfterMs: 0,
        audioKey: cue,
        audioMode: cue == null
            ? PhysicalGestureAudioMode.before
            : PhysicalGestureAudioMode.parallel,
      )
    else
      GroupGestureStep(
        moves: [_move(1)],
        pauseAfterMs: 0,
        audioKey: cue,
        audioMode: cue == null
            ? PhysicalGestureAudioMode.before
            : PhysicalGestureAudioMode.parallel,
      ),
    GroupGestureStep(moves: [_move(series ? 4 : 2)], pauseAfterMs: 0),
  ],
  stepPlayback: {0: PhysicalGestureStepPlayback(minimumDurationMs: minimum)},
);

void main() {
  tearDown(() {
    setSpeechAudioFiles({});
    setRequiredCatalogPaths([]);
    setObservedCatalogPaths([]);
  });

  test(
    'the exact supplied example uses six rods, shared numbers and one minimum per arithmetic step',
    () {
      final chain = _chain();
      final plan = physicalChainExamplePlan(chain);
      expect(plan.initialRods.length, 6);
      expect(plan.beadTransitionMs, 400);
      expect(plan.steps.length, 4);
      expect(plan.steps.first.audioKey, physicalExampleIntroKey);
      expect(plan.stepPlayback.keys, [1, 2]);
      expect(plan.stepPlayback.values.map((p) => p.minimumDurationMs), [
        3000,
        3000,
      ]);
      expect(plan.audioSequences[r'$physical-example:answer'], [
        physicalExampleAnswerKey,
        'number:1',
      ]);
      expect(abacusToNumber(compilePhysicalGesturePlan(plan).last.rods), 1);
      expect(chain.intermediates, [0, 250, 1]);
      expect(
        physicalGestureAudioKeys(plan),
        physicalChainExampleAudioKeys(chain),
      );
      final faster = physicalChainExamplePlan(chain, stepSec: 1.5);
      expect(faster.stepPlayback.values.map((p) => p.minimumDurationMs), [
        1500,
        1500,
      ]);
      expect(faster.beadTransitionMs, 400);
    },
  );

  for (final topic in topicCatalog) {
    test('worked example covers ${topic.id} on all three bank languages', () {
      final chain = generateChain(
        GenerateConfig(topicId: topic.id, actionCount: 5, signMode: 'mix'),
      );
      for (final locale in ['ru-RU', 'en-US', 'ar-XA']) {
        final plan = physicalChainExamplePlan(chain, locale: locale);
        expect(
          abacusToNumber(compilePhysicalGesturePlan(plan).last.rods),
          chain.answer,
        );
        expect(
          physicalGestureAudioKeys(plan),
          physicalChainExampleAudioKeys(chain, locale),
        );
        expect(plan.stepPlayback.length, chain.steps.length);
      }
    });
  }

  test(
    'invalid review intervals and negative semantic minimum are rejected',
    () {
      for (final seconds in [
        -1.0,
        0.0,
        0.01,
        31.0,
        double.nan,
        double.infinity,
      ]) {
        expect(
          () => physicalChainExamplePlan(_chain(), stepSec: seconds),
          throwsRangeError,
        );
      }
      expect(
        () => compilePhysicalGesturePlan(_timed(minimum: -1)),
        throwsRangeError,
      );
    },
  );

  test(
    'three-second minimum covers a whole series while frames remain 400 ms',
    () {
      fakeAsync((clock) {
        final frames = <int>[];
        var complete = 0;
        final player = PhysicalGesturePlayer(
          plan: _timed(series: true),
          speed: PhysicalGestureSpeed.medium,
          nowMs: () => clock.elapsed.inMilliseconds,
          onFrame: (_, _) => frames.add(clock.elapsed.inMilliseconds),
          onComplete: () => complete++,
        );
        player.play();
        clock.elapse(const Duration(milliseconds: 2999));
        expect(frames, [0, 400, 800]);
        expect(player.checkpointStepIndex, 0);
        clock.elapse(const Duration(milliseconds: 1));
        expect(frames, [0, 400, 800, 3000]);
        clock.elapse(const Duration(milliseconds: 400));
        expect(complete, 1);
        player.cancel();
      });
    },
  );

  test(
    'minimum includes hand approach and still waits for five-second speech',
    () {
      fakeAsync((clock) {
        final firstSpeech = Completer<void>();
        final approaches = <int>[];
        final frames = <int>[];
        final player = PhysicalGesturePlayer(
          plan: _timed(cue: 'operation'),
          speed: PhysicalGestureSpeed.medium,
          prepareMs: 300,
          nowMs: () => clock.elapsed.inMilliseconds,
          onCue: (_, _) => firstSpeech.future,
          onPrepare: (_, _) => approaches.add(clock.elapsed.inMilliseconds),
          onFrame: (_, _) => frames.add(clock.elapsed.inMilliseconds),
        );
        player.play();
        clock.elapse(const Duration(seconds: 5));
        expect(approaches, [0]);
        expect(frames, [300]);
        expect(player.checkpointStepIndex, 0);
        firstSpeech.complete();
        clock.flushMicrotasks();
        expect(approaches, [0, 5000]);
        clock.elapse(const Duration(milliseconds: 300));
        expect(frames, [300, 5300]);
        player.cancel();
      });
    },
  );

  test('natural long motion is never shortened by a smaller minimum', () {
    fakeAsync((clock) {
      final times = <int>[];
      final player = PhysicalGesturePlayer(
        plan: _timed(series: true, minimum: 100),
        speed: PhysicalGestureSpeed.medium,
        nowMs: () => clock.elapsed.inMilliseconds,
        onFrame: (_, _) => times.add(clock.elapsed.inMilliseconds),
      );
      player.play();
      clock.elapse(const Duration(milliseconds: 1200));
      expect(times, [0, 400, 800, 1200]);
      player.cancel();
    });
  });

  test('a user pause excludes wall time from the remaining minimum', () {
    fakeAsync((clock) {
      final times = <int>[];
      final plan = PhysicalGesturePlan(
        initialRods: [digitToBeads(0)],
        beadTransitionMs: 400,
        steps: [
          GroupGestureStep(moves: [_move(1)], pauseAfterMs: 0),
          GroupGestureStep(moves: [_move(2)], pauseAfterMs: 0),
        ],
        stepPlayback: const {
          0: PhysicalGestureStepPlayback(minimumDurationMs: 3000),
        },
      );
      final player = PhysicalGesturePlayer(
        plan: plan,
        speed: PhysicalGestureSpeed.medium,
        nowMs: () => clock.elapsed.inMilliseconds,
        onFrame: (_, _) => times.add(clock.elapsed.inMilliseconds),
      );
      player.play();
      clock.elapse(const Duration(seconds: 1));
      player.pause();
      clock.elapse(const Duration(seconds: 5));
      player.play();
      clock.elapse(const Duration(milliseconds: 1999));
      expect(times, [0]);
      clock.elapse(const Duration(milliseconds: 1));
      expect(times, [0, 8000]);
      player.cancel();
    });
  });

  test(
    'seek and cancellation invalidate pending minimum and late speech completion',
    () {
      fakeAsync((clock) {
        final speech = Completer<void>();
        var completed = 0;
        final frames = <int>[];
        final player = PhysicalGesturePlayer(
          plan: _timed(cue: 'operation'),
          speed: PhysicalGestureSpeed.medium,
          nowMs: () => clock.elapsed.inMilliseconds,
          onCue: (_, _) => speech.future,
          onFrame: (_, index) => frames.add(index),
          onComplete: () => completed++,
        );
        player.play();
        clock.elapse(const Duration(seconds: 1));
        player.seekToStep(1);
        player.play();
        clock.elapse(const Duration(milliseconds: 400));
        expect(completed, 1);
        expect(frames, [0, 1]);
        speech.complete();
        clock.flushMicrotasks();
        clock.elapse(const Duration(seconds: 10));
        expect(completed, 1);
        player.cancel();
      });
    },
  );

  testWidgets(
    'missing required clips keep the visible abacus idle without an instruction overlay',
    (tester) async {
      var completed = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhysicalChainExample(
              chain: _chain(),
              onComplete: () => completed++,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 10));
      expect(find.byType(AbacusWidget), findsOneWidget);
      expect(find.byType(TrainerInstructionScene), findsNothing);
      expect(completed, 0);
      expect(
        tester
            .widget<AbacusWidget>(find.byType(AbacusWidget))
            .rods
            .every((r) => r == digitToBeads(0)),
        isTrue,
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 4));
    },
  );

  testWidgets('failed required intro cannot finish the worked example', (
    tester,
  ) async {
    final chain = _chain();
    final keys = physicalChainExampleAudioKeys(chain);
    setSpeechAudioFiles({
      for (final (index, key) in keys.indexed)
        key: SpeechAudioFile(
          path: 'unit/unavailable-$index.mp3',
          durationMs: 50,
          locale: 'ru-RU',
        ),
    });
    setRequiredCatalogPaths(
      keys.indexed.map((e) => 'unit/unavailable-${e.$1}.mp3'),
    );
    var completed = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PhysicalChainExample(
            chain: chain,
            locale: 'ru-RU',
            stepSec: 0.1,
            onComplete: () => completed++,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 20));
    expect(completed, 0);
    expect(find.byType(TrainerInstructionScene), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 4));
  });
}
