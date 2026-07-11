import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/reading/letter_word_link/letter_word_link_trainer.dart';
import 'package:larnes_mobile/trainers/reading/letter_word_link/word_link_scene.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';
import 'package:larnes_mobile/trainers/shared/trainer_shell.dart';

void main() {
  group('LetterWordLinkTrainer', () {
    testWidgets('uses TrainerScene full-bleed without legacy instruction text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 640,
              child: LetterWordLinkTrainer(
                params: {
                  'entityCount': 4,
                  'letter': 'А',
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
      expect(find.byType(WordLinkScene), findsOneWidget);
      expect(find.textContaining('Соедини'), findsNothing);
      expect(find.textContaining('Молодец'), findsNothing);

      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('fills bounded stage', (tester) async {
      const stageKey = Key('letter-word-link-stage');

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              key: stageKey,
              width: 320,
              height: 480,
              child: LetterWordLinkTrainer(
                params: {
                  'entityCount': 3,
                  'letter': 'М',
                  'letterCase': 'upper',
                  'wordCase': 'lower',
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
