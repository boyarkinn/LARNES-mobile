import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/reading/word_cubes/word_cubes_trainer.dart';
import 'package:larnes_mobile/trainers/shared/instruction/trainer_instruction_scene.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/audio/clip_player.dart';

void main() {
  testWidgets('all words require all cubes and finish once; a new selection restarts', (tester) async {
    var completed = 0;
    Widget render(String slug) => MaterialApp(home: Scaffold(body: WordCubesTrainer(
      params: {'wordSlug': slug, '__runtimeSnapshot': {'version': 1, 'trainerKey': 'word-cubes', 'mode': 'materialized', 'payload': {'seed': 42}}},
      onComplete: () => completed++,
    )));
    await tester.pumpWidget(render('all'));
    await tester.pump();
    expect(find.byType(TrainerInstructionScene), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 999));
    expect(find.byType(TrainerInstructionScene), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('РИ|С'), findsOneWidget);
    Future<void> turn(String text) async {
      await tester.tap(find.text(text));
      await tester.pump();
    }
    Future<void> expectPulse(String text) async {
      final visual = find.ancestor(of: find.text(text), matching: find.byType(ScaleTransition)).first;
      await tester.pump(const Duration(milliseconds: 70));
      expect(tester.widget<ScaleTransition>(visual).scale.value, lessThan(0.98));
      await tester.pump(const Duration(milliseconds: 160));
      expect(tester.widget<ScaleTransition>(visual).scale.value, 1);
    }
    await turn('РЮ');
    expect(find.text('РИ'), findsOneWidget);
    await expectPulse('РИ');
    expect(completed, 0);
    for (final face in ['СУ', 'СЫ', 'СЭ']) { await turn(face); }
    expect(find.text('Верно!'), findsOneWidget);
    await expectPulse('С');
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('А|ЛО|Э'), findsOneWidget);
    expect(completed, 0);
    await turn('Э');
    for (final face in ['ЛЫ', 'ЛЭ', 'Л', 'ЛА']) { await turn(face); }
    for (final face in ['А', 'О', 'У', 'Ы']) {
      // Both red cubes may show А; select the final one by screen position.
      final candidates = find.text(face);
      await tester.tap(candidates.last); await tester.pump();
    }
    expect(find.text('Верно!'), findsOneWidget);
    await expectPulse('Э');
    await tester.pump(const Duration(seconds: 1));
    expect(completed, 1);
    await tester.pump(const Duration(seconds: 2)); expect(completed, 1);
    await tester.pumpWidget(render('ris'));
    expect(find.byType(TrainerInstructionScene), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await resetSharedClipPlayerForTests();
  });
}
