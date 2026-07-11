import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/reading/letter_place_in_word/fill_gap_scene.dart';
import 'package:larnes_mobile/trainers/reading/letter_place_in_word/gap_word_row.dart';
import 'package:larnes_mobile/trainers/reading/letter_place_in_word/letter_place_in_word_trainer.dart';
import 'package:larnes_mobile/trainers/reading/letter_place_in_word/word_card_with_gap.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';
import 'package:larnes_mobile/trainers/shared/trainer_shell.dart';

void main() {
  group('LetterPlaceInWordTrainer', () {
    testWidgets('uses TrainerScene full-bleed without legacy instruction text',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 640,
              child: LetterPlaceInWordTrainer(
                params: {
                  'practiceLetters': 'Д, А, М',
                  'entityCount': 2,
                  'distractorCount': 2,
                  'letterCase': 'upper',
                  'wordCase': 'upper',
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(TrainerScene), findsOneWidget);
      expect(find.byType(TrainerShell), findsNothing);
      expect(find.byType(FillGapScene), findsOneWidget);
      expect(find.byType(WordCardWithGap), findsWidgets);
      expect(find.byType(GapWordRow), findsWidgets);
      expect(find.textContaining('Поставь букву'), findsNothing);
      expect(find.textContaining('Молодец'), findsNothing);

      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('fills bounded stage', (tester) async {
      const stageKey = Key('letter-place-in-word-stage');

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              key: stageKey,
              width: 320,
              height: 480,
              child: LetterPlaceInWordTrainer(
                params: {
                  'practiceLetters': 'А, М',
                  'entityCount': 1,
                  'distractorCount': 2,
                  'letterCase': 'upper',
                  'wordCase': 'upper',
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
