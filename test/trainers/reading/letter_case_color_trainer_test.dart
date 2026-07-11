import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/reading/letter_case_color/case_color_scene.dart';
import 'package:larnes_mobile/trainers/reading/letter_case_color/letter_case_color_model.dart';
import 'package:larnes_mobile/trainers/reading/letter_case_color/letter_case_color_trainer.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';
import 'package:larnes_mobile/trainers/shared/trainer_shell.dart';

void main() {
  group('getDisplayCasePair', () {
    test('returns upper and lower forms for a letter', () {
      expect(
        getDisplayCasePair('а'),
        const DisplayCasePair(lower: 'а', upper: 'А'),
      );
    });

    test('normalizes input letter', () {
      expect(
        getDisplayCasePair('м'),
        const DisplayCasePair(lower: 'м', upper: 'М'),
      );
    });
  });

  group('LetterCaseColorTrainer', () {
    testWidgets('uses TrainerScene full-bleed without legacy instruction text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 640,
              child: LetterCaseColorTrainer(
                params: {'letter': 'А'},
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(TrainerScene), findsOneWidget);
      expect(find.byType(TrainerShell), findsNothing);
      expect(find.byType(CaseColorScene), findsOneWidget);
      expect(find.textContaining('Разукрась большую'), findsNothing);
      expect(find.textContaining('Разукрась маленькую'), findsNothing);
      expect(find.textContaining('Молодец'), findsNothing);

      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('shows clear and done buttons', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 640,
              child: LetterCaseColorTrainer(
                params: {'letter': 'О'},
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Стереть'), findsOneWidget);
      expect(find.text('Готово'), findsOneWidget);
    });

    testWidgets('fills bounded stage', (tester) async {
      const stageKey = Key('letter-case-color-stage');

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              key: stageKey,
              width: 320,
              height: 480,
              child: LetterCaseColorTrainer(
                params: {'letter': 'М'},
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.getSize(find.byKey(stageKey)), const Size(320, 480));
      expect(tester.getSize(find.byType(TrainerScene)), const Size(320, 480));
    });
  });
}
