import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/reading/letter_color/color_palette.dart';
import 'package:larnes_mobile/trainers/reading/letter_half_draw/half_draw_pad.dart';
import 'package:larnes_mobile/trainers/reading/letter_half_draw/letter_half_draw_trainer.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';
import 'package:larnes_mobile/trainers/shared/trainer_shell.dart';

void main() {
  group('LetterHalfDrawTrainer', () {
    testWidgets('uses TrainerScene full-bleed without legacy instruction text',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 640,
              child: LetterHalfDrawTrainer(
                params: {
                  'letter': 'А',
                  'letterCase': 'upper',
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(TrainerScene), findsOneWidget);
      expect(find.byType(TrainerShell), findsNothing);
      expect(find.byType(HalfDrawPad), findsOneWidget);
      expect(find.byType(ColorPalette), findsOneWidget);
      expect(find.textContaining('Дорисуй половину'), findsNothing);
      expect(find.textContaining('ПОХОЖЕСТЬ'), findsNothing);
      expect(find.textContaining('Молодец'), findsNothing);

      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('shows clear button before pass', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 640,
              child: LetterHalfDrawTrainer(
                params: {
                  'letter': 'М',
                  'letterCase': 'upper',
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Стереть'), findsOneWidget);
    });

    testWidgets('fills bounded stage', (tester) async {
      const stageKey = Key('letter-half-draw-stage');

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              key: stageKey,
              width: 320,
              height: 480,
              child: LetterHalfDrawTrainer(
                params: {
                  'letter': 'К',
                  'letterCase': 'upper',
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
