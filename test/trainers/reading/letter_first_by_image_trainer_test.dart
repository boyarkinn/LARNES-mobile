import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/reading/letter_first_by_image/letter_choice_bar.dart';
import 'package:larnes_mobile/trainers/reading/letter_first_by_image/letter_first_by_image_trainer.dart';
import 'package:larnes_mobile/trainers/reading/letter_first_by_image/word_card.dart';
import 'package:larnes_mobile/trainers/reading/sound_play_button.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';
import 'package:larnes_mobile/trainers/shared/trainer_shell.dart';

void main() {
  group('LetterFirstByImageTrainer', () {
    testWidgets('uses TrainerScene full-bleed without legacy instruction text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 640,
              child: LetterFirstByImageTrainer(
                params: {
                  'wordSlug': 'stork',
                  'wordCase': 'upper',
                  'letterCase': 'upper',
                  'distractorCount': 3,
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(TrainerScene), findsOneWidget);
      expect(find.byType(TrainerShell), findsNothing);
      expect(find.byType(WordCard), findsOneWidget);
      expect(find.byType(SoundPlayButton), findsOneWidget);
      expect(find.textContaining('Первая буква'), findsNothing);
      expect(find.textContaining('Молодец'), findsNothing);

      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('shows letter choice bar after stimulus reveal', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 640,
              child: LetterFirstByImageTrainer(
                params: {
                  'wordSlug': 'cat',
                  'wordCase': 'upper',
                  'letterCase': 'upper',
                  'distractorCount': 3,
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(LetterChoiceBar), findsNothing);

      await tester.pump(const Duration(milliseconds: 2500));
      await tester.pump();

      expect(find.byType(LetterChoiceBar), findsOneWidget);
    });

    testWidgets('fills bounded stage', (tester) async {
      const stageKey = Key('letter-first-by-image-stage');

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              key: stageKey,
              width: 320,
              height: 480,
              child: LetterFirstByImageTrainer(
                params: {
                  'wordSlug': 'house',
                  'wordCase': 'upper',
                  'letterCase': 'upper',
                  'distractorCount': 3,
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
