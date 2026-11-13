import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/reading/reading_cloze/reading_cloze_trainer.dart';
import 'package:larnes_mobile/trainers/reading/reading_main_idea/reading_main_idea_trainer.dart';
import 'package:larnes_mobile/trainers/reading/reading_reread/reading_reread_trainer.dart';

Map<String, dynamic> params(String trainerKey, Map<String, dynamic> payload) =>
    {
      '__runtimeSnapshot': {
        'version': 1,
        'mode': 'materialized',
        'trainerKey': trainerKey,
        'payload': payload,
      },
    };
Widget stage(Widget child) => MaterialApp(
  home: Scaffold(
    body: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(width: 320, height: 480, child: child),
    ),
  ),
);

void main() {
  testWidgets(
    'all 20 authored cloze choices remain reachable on a phone stage',
    (tester) async {
      var completed = 0;
      final choices = List.generate(
        20,
        (index) => 'Полный вариант ответа ${index + 1}',
      );
      await tester.pumpWidget(
        stage(
          ReadingClozeTrainer(
            params: params('reading-cloze', {
              'prompt': 'Выбери последний вариант.',
              'choices': choices,
              'correctIndex': 19,
            }),
            onComplete: () => completed++,
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 3));
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(find.text(choices.last), 250);
      await tester.tap(find.text(choices.last));
      expect(completed, 1);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'main idea choices and confirmation sentences scroll independently',
    (tester) async {
      var completed = 0;
      final choices = List.generate(
        20,
        (index) => 'Развёрнутая главная мысль ${index + 1}',
      );
      final sentences = List.generate(
        20,
        (index) => 'Подтверждающее предложение ${index + 1}.',
      );
      await tester.pumpWidget(
        stage(
          ReadingMainIdeaTrainer(
            params: params('reading-main-idea', {
              'text': 'Учебный текст.',
              'choices': choices,
              'correctIndex': 19,
              'sentences': sentences,
              'confirm': sentences.last,
            }),
            onComplete: () => completed++,
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 3));
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(find.text(choices.last), 250);
      await tester.tap(find.text(choices.last));
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(find.text(sentences.last), 250);
      await tester.tap(find.text(sentences.last));
      expect(completed, 1);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('reread keeps the current question during a parent rebuild', (
    tester,
  ) async {
    final frozen = params('reading-reread', {
      'text': 'Учебный текст.',
      'questions': [
        {
          'prompt': 'Первый вопрос?',
          'choices': ['Первый ответ', 'Второй ответ'],
          'correctIndex': 0,
        },
        {
          'prompt': 'Второй вопрос?',
          'choices': ['Третий ответ', 'Четвёртый ответ'],
          'correctIndex': 1,
        },
      ],
    });
    Widget render() => stage(ReadingRereadTrainer(params: {...frozen}));
    await tester.pumpWidget(render());
    await tester.pump(const Duration(seconds: 3));
    for (var round = 0; round < 2; round++) {
      await tester.tap(find.text('Старт'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('Стоп'));
      await tester.pump();
      await tester.tap(find.text('Дальше'));
      await tester.pump();
      await tester.tap(find.text(round == 0 ? 'Ещё раз' : 'К вопросу'));
      await tester.pump();
    }
    await tester.tap(find.text('Первый ответ'));
    await tester.pump();
    await tester.tap(find.text('Дальше'));
    await tester.pump();
    expect(find.text('Второй вопрос?'), findsOneWidget);
    await tester.pumpWidget(render());
    await tester.pump();
    expect(find.text('Второй вопрос?'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
