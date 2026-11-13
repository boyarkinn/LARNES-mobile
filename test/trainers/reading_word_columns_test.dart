import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/shared/shuffled_cycle.dart';
import 'package:larnes_mobile/trainers/reading/reading_word_columns/reading_word_columns_trainer.dart';

void main() {
  test('all words repeat in shuffled cycles without a boundary duplicate', () {
    for (final size in [1, 2, 17, 292]) {
      var state = ShuffledCycle.create(size, 4264);
      int? previous;
      for (var cycle = 0; cycle < 5; cycle++) {
        final seen = <int>{};
        for (var i = 0; i < size; i++) {
          final current = state.order[state.position];
          if (size > 1 && i == 0) expect(current, isNot(previous));
          expect(seen.add(current), isTrue);
          previous = current;
          state = ShuffledCycle.restore(state.advance().toJson(), size)!;
          expect(state.consumed, cycle * size + i + 1);
        }
        expect(seen.length, size);
      }
    }
  });
  testWidgets(
    'start, confirmed reading and finish preserve accents and count only Next',
    (tester) async {
      var completed = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReadingWordColumnsTrainer(
              params: const {
                '__runtimeSnapshot': {
                  'version': 1,
                  'trainerKey': 'reading-word-columns',
                  'mode': 'materialized',
                  'payload': {
                    'words': ['и́ва'],
                  },
                },
              },
              onComplete: () => completed++,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 13));
      await tester.tap(find.text('Start'));
      await tester.pump();
      expect(find.text('и́ва'), findsOneWidget);
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.text('Next'));
        await tester.pump();
      }
      await tester.tap(find.text('Finish'));
      await tester.pump();
      expect(find.text('3'), findsOneWidget);
      expect(completed, 1);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
