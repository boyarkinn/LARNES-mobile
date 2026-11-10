import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/abacus_playback_plan.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/abacus_playback_timing.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/example_parser.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_model.dart';
import 'package:larnes_mobile/trainers/shared/trainer_playback_controller.dart';

List<AbacusPlaybackEvent> exampleEvents() {
  return buildAbacusPlaybackPlan(
    AbacusPlaybackPlan(
      actions: parseExampleActions('+49 +22'),
      gestures: [
        AbacusGestureFrame(
          actionIndex: 0,
          rodIndices: const [0, 1],
          rods: numberToAbacus(49, 2),
          value: 49,
        ),
        AbacusGestureFrame(
          actionIndex: 1,
          rodIndices: const [0],
          rods: numberToAbacus(69, 2),
          value: 69,
        ),
        AbacusGestureFrame(
          actionIndex: 1,
          rodIndices: const [1],
          rods: numberToAbacus(71, 2),
          value: 71,
        ),
      ],
    ),
  );
}

void main() {
  group('shared abacus playback', () {
    test('keeps action audio separate from intermediate gestures', () {
      final events = exampleEvents();
      expect(events.map((event) => event.type).toList(), [
        AbacusPlaybackEventType.actionStart,
        AbacusPlaybackEventType.gesture,
        AbacusPlaybackEventType.actionComplete,
        AbacusPlaybackEventType.actionStart,
        AbacusPlaybackEventType.gesture,
        AbacusPlaybackEventType.gesture,
        AbacusPlaybackEventType.actionComplete,
        AbacusPlaybackEventType.complete,
      ]);
      expect(
        events
            .where((event) => event.type == AbacusPlaybackEventType.gesture)
            .map((event) => event.value)
            .toList(),
        [49, 69, 71],
      );
      expect(events.last.value, 71);
    });

    test('finishes an empty scene without an action', () {
      final events = buildAbacusPlaybackPlan(
        const AbacusPlaybackPlan(actions: [], gestures: []),
      );
      expect(events.length, 1);
      expect(events.single.type, AbacusPlaybackEventType.complete);
      expect(events.single.value, 0);
    });

    test('preserves both tempo contracts', () {
      final events = exampleEvents();
      expect(
        abacusPlaybackDelayBefore(events, 1, AbacusPlaybackMode.digital, 0.5),
        700,
      );
      expect(
        abacusPlaybackDelayBefore(events, 4, AbacusPlaybackMode.digital, 2),
        2000,
      );
      expect(
        abacusPlaybackDelayBefore(
          events,
          1,
          AbacusPlaybackMode.visualization,
          2,
        ),
        2000,
      );
      expect(
        abacusPlaybackDelayBefore(
          events,
          5,
          AbacusPlaybackMode.visualization,
          2,
        ),
        500,
      );
      expect(
        abacusPlaybackDelayBefore(
          events,
          6,
          AbacusPlaybackMode.visualization,
          2,
        ),
        500,
      );
    });

    test('pauses in a wait and resumes without another action start', () {
      fakeAsync((async) {
        final events = exampleEvents();
        final seen = <(AbacusPlaybackEventType, int)>[];
        final controller = TrainerPlaybackController<AbacusPlaybackEvent>(
          events: events,
          delayBeforeMs: (event, index) => abacusPlaybackDelayBefore(
            events,
            index,
            AbacusPlaybackMode.visualization,
            0.5,
          ),
          onEvent: (event, index) =>
              seen.add((event.type, async.elapsed.inMilliseconds)),
          nowMs: () => async.elapsed.inMilliseconds,
        );

        controller.play();
        expect(seen, [(AbacusPlaybackEventType.actionStart, 0)]);
        async.elapse(const Duration(milliseconds: 200));
        controller.pause();
        async.elapse(const Duration(seconds: 1));
        expect(seen.length, 1);
        controller.play();
        async.elapse(const Duration(milliseconds: 299));
        expect(seen.length, 1);
        async.elapse(const Duration(milliseconds: 1));
        expect(seen[1], (AbacusPlaybackEventType.gesture, 1500));
        async.elapse(const Duration(seconds: 2));
        expect(controller.status, TrainerPlaybackStatus.complete);
        expect(
          seen
              .where((entry) => entry.$1 == AbacusPlaybackEventType.actionStart)
              .length,
          2,
        );
        expect(
          seen
              .where((entry) => entry.$1 == AbacusPlaybackEventType.gesture)
              .map((entry) => entry.$2)
              .toList(),
          [1500, 2500, 3000],
        );
      });
    });

    test('step, seek, cancel and replay remove stale timers', () {
      fakeAsync((async) {
        final seen = <int>[];
        final seeks = <int>[];
        final controller = TrainerPlaybackController<int>(
          events: [0, 1, 2],
          delayBeforeMs: (event, index) => 100,
          onEvent: (event, index) => seen.add(event),
          onSeek: seeks.add,
          nowMs: () => async.elapsed.inMilliseconds,
        );

        controller.play();
        async.elapse(const Duration(milliseconds: 40));
        expect(controller.stepForward(), 0);
        async.elapse(const Duration(milliseconds: 500));
        expect(seen, [0]);
        controller.stepBackward();
        expect(controller.nextIndex, 0);
        controller.seek(2);
        controller.play();
        async.elapse(const Duration(milliseconds: 50));
        controller.cancel();
        async.elapse(const Duration(milliseconds: 500));
        expect(seen, [0]);
        controller.replay();
        async.elapse(const Duration(milliseconds: 300));
        expect(seen, [0, 0, 1, 2]);
        expect(seeks, [0, 2, 0]);
        expect(controller.status, TrainerPlaybackStatus.complete);
      });
    });
  });
}
