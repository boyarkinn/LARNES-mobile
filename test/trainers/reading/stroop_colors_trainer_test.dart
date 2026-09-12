import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/reading/stroop_colors/stroop_colors_scene.dart';
import 'package:larnes_mobile/trainers/reading/stroop_colors/stroop_colors_trainer.dart';
import 'package:larnes_mobile/trainers/shared/instruction/trainer_instruction_scene.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';
import 'package:larnes_mobile/trainers/shared/trainer_shell.dart';

void main() {
  group('StroopColorsTrainer', () {
    testWidgets('starts in instruction phase without the word scene', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 640,
              child: StroopColorsTrainer(
                params: {'wordCount': 3, 'displaySeconds': 3},
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(TrainerScene), findsOneWidget);
      expect(find.byType(TrainerInstructionScene), findsOneWidget);
      expect(find.byType(TrainerShell), findsNothing);
      expect(find.byType(StroopColorsScene), findsNothing);
      expect(find.textContaining('Молодец'), findsNothing);
      expect(find.byType(ElevatedButton), findsNothing);
      expect(find.byType(TextButton), findsNothing);
    });

    testWidgets('fills bounded stage', (tester) async {
      const stageKey = Key('stroop-colors-stage');

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              key: stageKey,
              width: 320,
              height: 480,
              child: StroopColorsTrainer(
                params: {'wordCount': 2, 'displaySeconds': 2},
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.getSize(find.byKey(stageKey)), const Size(320, 480));
      expect(tester.getSize(find.byType(TrainerScene)), const Size(320, 480));
      expect(find.byType(StroopColorsScene), findsNothing);
    });
  });
}
