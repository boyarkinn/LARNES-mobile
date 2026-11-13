import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/shared/active_clock.dart';
import 'package:larnes_mobile/trainers/reading/shared/timed_word_session.dart';
import 'package:larnes_mobile/trainers/reading/reading_marathon/model.dart';
import 'package:larnes_mobile/trainers/reading/reading_marathon/reading_marathon_trainer.dart';
import 'package:larnes_mobile/trainers/runtime/trainer_pause_scope.dart';
import 'package:larnes_mobile/trainers/runtime/trainer_time_progress.dart';
import 'package:larnes_mobile/trainers/runtime/trainer_play_shell.dart';

void main() {
  testWidgets(
    'round time occupies its own HUD line and preserves assignment progress',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TrainerPlayShell(
            currentStep: 1,
            totalSteps: 2,
            menuContinueLabel: 'Continue',
            menuExitLabel: 'Exit',
            onExit: () {},
            child: const Stack(children: [TrainerTimeProgress(value: .25)]),
          ),
        ),
      );
      await tester.pump();
      final fills = tester
          .widgetList<AnimatedFractionallySizedBox>(
            find.byType(AnimatedFractionallySizedBox),
          )
          .map((widget) => widget.widthFactor)
          .toList();
      expect(fills, containsAll([.5, .25]));
      expect(find.text('25'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );
  test('clock excludes pauses and delayed ticks do not extend a round', () {
    var now = 0;
    final clock = ActiveClock(1200, now: () => now)..start();
    now = 4200;
    expect(clock.pause(), 5400);
    now = 100000;
    expect(clock.read(), 5400);
    clock.start();
    now += 54600;
    expect(clock.read(), 60000);
  });
  test('all rounds cycle the frozen order; a deadline click adds no word', () {
    var state = TimedWordSession.create(3, 5784, 4);
    final order = state.order;
    for (var round = 0; round < 4; round++) {
      state = state.copy(phase: 'reading');
      for (var i = 0; i < 5; i++) {
        expect(state.wordIndex, order[i % 3]);
        state = state.confirm(i * 10, marathonDurations);
      }
      state = TimedWordSession.restore(state.toJson(), 3, marathonDurations)!;
      state = state.confirm(marathonDurations[round], marathonDurations);
      expect(state.counts[round], 5);
      expect(state.phase, round == 3 ? 'result' : 'prompt');
    }
    expect(state.counts, [5, 5, 5, 5]);
    expect(
      marathonFinalKeys([20, 0, 0, 41], 'ru-RU'),
      contains('number:one:neuter'),
    );
    expect(
      marathonFinalKeys([20, 0, 0, 31], 'ru-RU')!.last,
      'feedback:reading:word-many',
    );
    expect(
      marathonFinalKeys([20, 0, 0, 18], 'ru-RU'),
      isNot(contains('feedback:reading:more')),
    );
  });
  testWidgets(
    'four timed rounds, pause, announcements without counts, final comparison',
    (tester) async {
      var now = 0, completed = 0, paused = false;
      late StateSetter setPaused;
      final cues = <List<String>>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                setPaused = setState;
                return TrainerPauseScope(
                  paused: paused,
                  child: ReadingMarathonTrainer(
                    params: const {
                      '__runtimeSnapshot': {
                        'version': 1,
                        'trainerKey': 'reading-marathon',
                        'mode': 'materialized',
                        'payload': {
                          'words': ['и́ва'],
                        },
                      },
                    },
                    clockNow: () => now,
                    playCues: (keys) async {
                      cues.add(keys);
                      return true;
                    },
                    onComplete: () => completed++,
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 10));
      await tester.pump();
      for (var round = 0; round < 4; round++) {
        expect(find.text('Start'), findsNothing);
        expect(find.text('Finish'), findsNothing);
        for (final label in ['3', '2', '1']) {
          expect(find.text(label), findsOneWidget);
          expect(find.text('и́ва'), findsNothing);
          await tester.pump(const Duration(seconds: 1));
        }
        expect(find.text('и́ва'), findsOneWidget);
        expect(find.text('60'), findsNothing);
        if (round == 0) {
          setPaused(() => paused = true);
          await tester.pump();
          now += 90000;
          await tester.pump(const Duration(seconds: 1));
          expect(
            tester
                .widget<TrainerTimeProgressBar>(
                  find.byType(TrainerTimeProgressBar),
                )
                .value,
            0,
          );
          setPaused(() => paused = false);
          await tester.pump();
        }
        for (var i = 0; i < round + 1; i++) {
          await tester.tap(find.text('Next'));
        }
        await tester.pump();
        now += marathonDurations[round];
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump();
        await tester.pump();
        if (round < 3) {
          expect(find.textContaining('Your result'), findsNothing);
        }
      }
      expect(cues.length, 4);
      expect(find.textContaining('first minute is 1'), findsOneWidget);
      expect(find.textContaining('last minute 4'), findsOneWidget);
      expect(completed, 1);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
