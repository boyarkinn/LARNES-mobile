import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/reading/letter_draw_show/draw_round_dots.dart';
import 'package:larnes_mobile/trainers/reading/letter_draw_show/draw_scene.dart';
import 'package:larnes_mobile/trainers/reading/letter_draw_show/letter_draw_show_trainer.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';
import 'package:larnes_mobile/trainers/shared/trainer_shell.dart';

void main() {
  group('LetterDrawShowTrainer', () {
    testWidgets('uses TrainerScene full-bleed without legacy instruction text',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 640,
              child: LetterDrawShowTrainer(
                params: {
                  'letter': 'А',
                  'letterCase': 'upper',
                  'rounds': 3,
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(TrainerScene), findsOneWidget);
      expect(find.byType(TrainerShell), findsNothing);
      expect(find.byType(DrawScene), findsOneWidget);
      expect(find.byType(DrawRoundDots), findsOneWidget);
      expect(find.textContaining('Молодец'), findsNothing);
      expect(find.textContaining('Смотри'), findsNothing);

      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('hides round dots for single round', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 640,
              child: LetterDrawShowTrainer(
                params: {
                  'letter': 'А',
                  'letterCase': 'upper',
                  'rounds': 1,
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(DrawScene), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(DrawRoundDots),
          matching: find.byType(Row),
        ),
        findsNothing,
      );
    });

    testWidgets('shows fallback for unsupported letter', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 640,
              child: LetterDrawShowTrainer(
                params: {
                  'letter': 'Q',
                  'letterCase': 'upper',
                  'rounds': 1,
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.textContaining('не найден'), findsOneWidget);
      expect(find.byType(DrawScene), findsNothing);
    });

    testWidgets('fills bounded stage', (tester) async {
      const stageKey = Key('letter-draw-show-stage');

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              key: stageKey,
              width: 320,
              height: 480,
              child: LetterDrawShowTrainer(
                params: {
                  'letter': 'О',
                  'letterCase': 'upper',
                  'rounds': 1,
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
