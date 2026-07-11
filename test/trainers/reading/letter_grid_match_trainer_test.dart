import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/reading/letter_grid_match/grid_match_scene.dart';
import 'package:larnes_mobile/trainers/reading/letter_grid_match/letter_grid_match_trainer.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';
import 'package:larnes_mobile/trainers/shared/trainer_shell.dart';

void main() {
  group('LetterGridMatchTrainer', () {
    testWidgets('uses TrainerScene full-bleed without legacy instruction text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 640,
              child: LetterGridMatchTrainer(
                params: {
                  'filledCount': 4,
                  'gridSize': 3,
                  'letterCase': 'upper',
                  'practiceLetters': 'А, М, К',
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(TrainerScene), findsOneWidget);
      expect(find.byType(TrainerShell), findsNothing);
      expect(find.byType(GridMatchScene), findsOneWidget);
      expect(find.textContaining('Сделай правый'), findsNothing);
      expect(find.textContaining('Образец'), findsNothing);
      expect(find.textContaining('Перетащи буквы'), findsNothing);
      expect(find.textContaining('Молодец'), findsNothing);

      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('uses admin form aliases for round size', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 640,
              child: LetterGridMatchTrainer(
                params: {
                  'digit': 3,
                  'entityCount': 5,
                  'letterCase': 'upper',
                  'practiceLetters': 'А, М, К',
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(GridMatchScene), findsOneWidget);
    });

    testWidgets('fills bounded stage', (tester) async {
      const stageKey = Key('letter-grid-match-stage');

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              key: stageKey,
              width: 320,
              height: 480,
              child: LetterGridMatchTrainer(
                params: {
                  'filledCount': 3,
                  'gridSize': 2,
                  'letterCase': 'lower',
                  'practiceLetters': 'А, Б',
                },
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
