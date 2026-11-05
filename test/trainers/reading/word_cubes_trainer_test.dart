import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/reading/word_cubes/word_cubes_trainer.dart';
import 'package:larnes_mobile/trainers/shared/instruction/trainer_instruction_scene.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/audio/clip_player.dart';

void main() {
  testWidgets('warehouses change after rotation, rapid taps cannot skip, and all words finish once', (tester) async {
    final semantics = tester.ensureSemantics(); addTearDown(semantics.dispose);
    var completed = 0;
    Widget render(String slug) => MaterialApp(home: Scaffold(body: WordCubesTrainer(
      params: {'wordSlug': slug, '__runtimeSnapshot': {'version': 1, 'trainerKey': 'word-cubes', 'mode': 'materialized', 'payload': {'seed': 42}}},
      onComplete: () => completed++,
    )));
    await tester.pumpWidget(render('all')); await tester.pump();
    expect(find.byType(TrainerInstructionScene), findsOneWidget);
    await tester.pump(const Duration(seconds: 3)); await tester.pump();
    await tester.pump(const Duration(milliseconds: 999));
    expect(find.byType(TrainerInstructionScene), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1)); await tester.pumpAndSettle();
    Finder cube(int index, String face) => find.bySemanticsLabel('Кубик ${index + 1}, склад $face. Нажми, чтобы изменить склад');
    Future<void> turn(int index, String face) async {
      await tester.tap(cube(index, face)); await tester.pump();
      await tester.pump(const Duration(milliseconds: 210));
      expect(cube(index, face), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 220)); await tester.pump();
    }
    expect(find.text('РИ|С'), findsOneWidget);
    await tester.tap(cube(0, 'РЮ')); await tester.tap(cube(0, 'РЮ')); await tester.pump();
    await tester.pump(const Duration(milliseconds: 210)); expect(cube(0, 'РЮ'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 220)); await tester.pump();
    expect(cube(0, 'РИ'), findsOneWidget); expect(completed, 0);
    for (final face in ['СУ', 'СЫ', 'СЭ']) { await turn(1, face); }
    expect(find.text('Верно!'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1)); await tester.pumpAndSettle();
    expect(find.text('А|ЛО|Э'), findsOneWidget); expect(completed, 0);
    await turn(0, 'Э');
    for (final face in ['ЛЫ', 'ЛЭ', 'Л', 'ЛА']) { await turn(1, face); }
    for (final face in ['А', 'О', 'У', 'Ы']) { await turn(2, face); }
    expect(find.text('Верно!'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1)); expect(completed, 1);
    await tester.pump(const Duration(seconds: 2)); expect(completed, 1);
    await tester.pumpWidget(render('ris')); expect(find.byType(TrainerInstructionScene), findsOneWidget);
    await tester.pumpWidget(const SizedBox()); await resetSharedClipPlayerForTests();
  });
}
