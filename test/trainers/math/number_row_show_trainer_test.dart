import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/math/number_row_show/number_row_interactive_scene.dart';
import 'package:larnes_mobile/trainers/math/number_row_show/number_row_show_trainer.dart';
import 'package:larnes_mobile/trainers/shared/instruction/trainer_instruction_scene.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';
import 'package:larnes_mobile/trainers/shared/trainer_shell.dart';

void main() {
  group('NumberRowShowTrainer', () {
    testWidgets('starts with instruction scene', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 640,
              child: NumberRowShowTrainer(
                params: {'digit': 4, 'stepPauseSec': 0.5},
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(TrainerScene), findsOneWidget);
      expect(find.byType(TrainerShell), findsNothing);
      expect(find.byType(TrainerInstructionScene), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('fills bounded stage', (tester) async {
      const stageKey = Key('number-row-stage');

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              key: stageKey,
              width: 320,
              height: 480,
              child: NumberRowShowTrainer(
                params: {'digit': 5, 'stepPauseSec': 0.5},
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.getSize(find.byKey(stageKey)), const Size(320, 480));
      expect(tester.getSize(find.byType(TrainerScene)), const Size(320, 480));

      await tester.pump(const Duration(milliseconds: 500));
    });
  });

  group('NumberRowInteractiveScene', () {
    testWidgets('reveals digits progressively on show phase', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 640,
              child: NumberRowInteractiveScene(
                studyDigit: 2,
                stepPauseSec: 0.5,
                onComplete: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('0'), findsNothing);
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.text('0'), findsOneWidget);
    });
  });
}
