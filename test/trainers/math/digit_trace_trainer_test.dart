import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/math/digit_trace/digit_trace_trainer.dart';
import 'package:larnes_mobile/trainers/math/digit_trace/trace_pad.dart';
import 'package:larnes_mobile/trainers/shared/instruction/trainer_instruction_scene.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';
import 'package:larnes_mobile/trainers/shared/trainer_shell.dart';

void main() {
  group('DigitTraceTrainer', () {
    testWidgets('uses TrainerScene full-bleed without legacy instruction text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 640,
              child: DigitTraceTrainer(
                params: {'digit': 5},
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(TrainerScene), findsOneWidget);
      expect(find.byType(TrainerShell), findsNothing);
      expect(find.byType(TrainerInstructionScene), findsOneWidget);
      expect(find.textContaining('ПОХОЖЕСТЬ'), findsNothing);
      expect(find.textContaining('Молодец'), findsNothing);
      expect(find.textContaining('попробовать снова'), findsNothing);
    });

    testWidgets('shows trace pad after instruction and countdown', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 640,
              child: DigitTraceTrainer(
                params: {'digit': 3},
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(TracePad), findsNothing);

      await tester.pump(const Duration(seconds: 8));
      await tester.pump();

      expect(find.byType(TracePad), findsOneWidget);
      expect(find.text('Стереть'), findsOneWidget);
    });

    testWidgets('fills bounded stage', (tester) async {
      const stageKey = Key('trace-stage');

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              key: stageKey,
              width: 320,
              height: 480,
              child: DigitTraceTrainer(
                params: {'digit': 2},
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
