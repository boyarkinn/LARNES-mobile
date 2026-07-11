import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/flashcard_digit_match/flashcard_digit_match_trainer.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/flashcard_digit_match/match_board.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';

void main() {
  group('FlashcardDigitMatchTrainer', () {
    testWidgets('uses TrainerScene without in-trainer instructions', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 390,
              height: 720,
              child: FlashcardDigitMatchTrainer(
                params: {
                  'totalRods': 2,
                  'values': [3, 7],
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(TrainerScene), findsOneWidget);
      expect(find.byType(MatchBoard), findsOneWidget);
      expect(find.textContaining('Проведи пальцем'), findsNothing);
      expect(find.textContaining('Соединено'), findsNothing);
      expect(find.textContaining('Все пары'), findsNothing);
      expect(find.textContaining('соедини'), findsNothing);
    });

    testWidgets('fills bounded stage', (tester) async {
      const stageKey = Key('flashcard-stage');

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              key: stageKey,
              width: 360,
              height: 480,
              child: FlashcardDigitMatchTrainer(
                params: {
                  'totalRods': 1,
                  'values': [0, 1, 2],
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.getSize(find.byKey(stageKey)), const Size(360, 480));
      expect(tester.getSize(find.byType(TrainerScene)), const Size(360, 480));
    });
  });
}
