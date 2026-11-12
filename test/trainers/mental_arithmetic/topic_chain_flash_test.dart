import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/topic_chain_flash/check_answer.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/topic_chain_flash/topic_chain_flash_trainer.dart';
import 'package:larnes_mobile/trainers/runtime/validate_params.dart';
import 'package:larnes_mobile/trainers/runtime/trainer_telemetry.dart';
import 'package:larnes_mobile/features/parent/models/parent_homework.dart';

void main() {
  group('topic-chain-flash check-answer', () {
    test('accepts exact and trims', () {
      expect(isCorrectAnswer('12', 12), isTrue);
      expect(isCorrectAnswer(' 12 ', 12), isTrue);
      expect(isCorrectAnswer('13', 12), isFalse);
    });
  });

  group('topic-chain-flash params', () {
    test('validates defaults and rejects bad topicId', () {
      final ok = validateTrainerParams('topic-chain-flash', {
        'topicId': 'simple-1',
        'actionCount': 5,
        'stepPauseSec': 1,
      });
      expect(ok.ok, isTrue);
      expect(ok.params?['exampleCount'], 1);
      expect(ok.params?['solveMode'], 'abacus');

      final withExamples = validateTrainerParams('topic-chain-flash', {
        'topicId': 'simple-1',
        'actionCount': 5,
        'exampleCount': 3,
        'solveMode': 'mental',
        'stepPauseSec': 1,
      });
      expect(withExamples.ok, isTrue);
      expect(withExamples.params?['exampleCount'], 3);
      expect(withExamples.params?['solveMode'], 'mental');

      final bad = validateTrainerParams('topic-chain-flash', {
        'topicId': 'nope',
        'actionCount': 5,
        'stepPauseSec': 1,
      });
      expect(bad.ok, isFalse);
    });
  });

  group('topic-chain-flash trainer', () {
    testWidgets('flash then answer field in bounded stage', (tester) async {
      var completed = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 390,
              height: 700,
              child: TopicChainFlashTrainer(
                onComplete: () => completed++,
                params: {
                  'topicId': 'simple-1',
                  'actionCount': 3,
                  'stepPauseSec': 0.05,
                },
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      // instruction silent (~1800) + countdown 3→2→1→Старт (4×750ms) + flash steps
      await tester.pump(const Duration(milliseconds: 1800));
      await tester.pump(const Duration(milliseconds: 3000));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Повторить цепочку'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '99999');
      await tester.pump();
      final checkButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Проверить'),
      );
      expect(checkButton.onPressed, isNotNull);
      await tester.tap(find.widgetWithText(FilledButton, 'Проверить'));
      await tester.pump();
      expect(completed, 1);
      // A terminal durable checkpoint cannot expose another replay/attempt.
      expect(find.text('Повторить цепочку'), findsNothing);
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Повторить цепочку'), findsNothing);
      await tester.pump(const Duration(milliseconds: 150));
    });

    testWidgets(
      'one attempt per example records errors and completes an all-wrong series',
      (tester) async {
        final events = <Map<String, dynamic>>[];
        var completed = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TrainerTelemetryScope(
                descriptor: const LessonTrainerTelemetryDescriptor(
                  reportToken: 'unit',
                  reportUrl: '/unit',
                  runId: 'one-attempt-chain',
                ),
                sender: (_, event) async {
                  events.add(event);
                },
                stepIndex: 0,
                totalSteps: 1,
                trainerKey: 'topic-chain-flash',
                trainerTitle: 'Chain',
                child: TopicChainFlashTrainer(
                  params: const {
                    'topicId': 'simple-1',
                    'actionCount': 3,
                    'exampleCount': 2,
                    'stepPauseSec': 0.05,
                  },
                  onComplete: () => completed++,
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1800));
        await tester.pump(const Duration(milliseconds: 3000));
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.byType(TextField), findsOneWidget);
        final field = tester.widget<TextField>(find.byType(TextField));
        field.onSubmitted?.call('');
        await tester.enterText(find.byType(TextField), '-');
        field.onSubmitted?.call('-');
        await tester.pump();
        expect(
          events.where((event) => event['eventType'] == 'interaction'),
          isEmpty,
        );
        await tester.enterText(find.byType(TextField), '99999');
        final submit = tester
            .widget<TextField>(find.byType(TextField))
            .onSubmitted!;
        submit('99999');
        submit('99999');
        await tester.pump();
        expect(find.byType(TextField), findsNothing);
        expect(completed, 0);
        var answers = events
            .where((event) => event['eventType'] == 'interaction')
            .toList();
        expect(answers.length, 1);
        expect(answers.single['correct'], isFalse);
        expect(answers.single['progressCurrent'], 1);
        await tester.pump(const Duration(milliseconds: 3000));
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.byType(TextField), findsOneWidget);
        expect(
          tester.widget<TextField>(find.byType(TextField)).controller?.text,
          '',
        );
        await tester.enterText(find.byType(TextField), '99999');
        final lastSubmit = tester
            .widget<TextField>(find.byType(TextField))
            .onSubmitted!;
        lastSubmit('99999');
        lastSubmit('99999');
        await tester.pump();
        expect(completed, 1);
        answers = events
            .where((event) => event['eventType'] == 'interaction')
            .toList();
        expect(answers.map((event) => event['correct']), [false, false]);
        expect(answers.map((event) => event['progressCurrent']), [1, 2]);
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(milliseconds: 150));
      },
    );
  });
}
