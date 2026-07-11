import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/reading/letter_name_aloud/letter_name_aloud_trainer.dart';
import 'package:larnes_mobile/trainers/reading/letter_name_aloud/name_aloud_dots.dart';
import 'package:larnes_mobile/trainers/reading/letter_name_aloud/name_aloud_scene.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';
import 'package:larnes_mobile/trainers/shared/trainer_shell.dart';

void main() {
  group('LetterNameAloudTrainer', () {
    testWidgets('uses TrainerScene full-bleed without legacy instruction text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 640,
              child: LetterNameAloudTrainer(
                params: {
                  'practiceLetters': 'А, М, К',
                  'letterCase': 'upper',
                  'displaySeconds': 3,
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(TrainerScene), findsOneWidget);
      expect(find.byType(TrainerShell), findsNothing);
      expect(find.byType(NameAloudScene), findsOneWidget);
      expect(find.byType(NameAloudDots), findsOneWidget);
      expect(find.textContaining('Назови'), findsNothing);
      expect(find.textContaining('Молодец'), findsNothing);
      expect(find.textContaining('/'), findsNothing);

      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('fills bounded stage', (tester) async {
      const stageKey = Key('letter-name-aloud-stage');

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              key: stageKey,
              width: 320,
              height: 480,
              child: LetterNameAloudTrainer(
                params: {
                  'practiceLetters': 'А, Б',
                  'letterCase': 'upper',
                  'displaySeconds': 2,
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
