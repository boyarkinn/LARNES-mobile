import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/static_example_show/example_bridge.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/static_example_show/static_abacus_widget.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/static_example_show/static_example_show_trainer.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';
import 'package:larnes_mobile/trainers/shared/trainer_shell.dart';

void main() {
  group('StaticExampleShowTrainer', () {
    testWidgets('uses TrainerScene full-bleed without legacy TrainerShell', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 640,
              child: StaticExampleShowTrainer(
                params: {
                  'operation': 'add',
                  'operandA': 6,
                  'operandB': 3,
                  'totalRods': 2,
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(TrainerScene), findsOneWidget);
      expect(find.byType(TrainerShell), findsNothing);
      expect(find.byType(AnimatedStaticAbacusValue), findsNWidgets(2));
      expect(find.byType(StaticAbacusWidget), findsNWidgets(2));
      expect(find.byType(ExampleBridge), findsOneWidget);
      expect(find.text('6 + 3'), findsOneWidget);
    });

    testWidgets('fills bounded stage', (tester) async {
      const stageKey = Key('static-example-stage');

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              key: stageKey,
              width: 320,
              height: 480,
              child: StaticExampleShowTrainer(
                params: {
                  'operation': 'subtract',
                  'operandA': 10,
                  'operandB': 9,
                  'totalRods': 2,
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.getSize(find.byKey(stageKey)), const Size(320, 480));
      expect(tester.getSize(find.byType(TrainerScene)), const Size(320, 480));
      expect(find.text('10 − 9'), findsOneWidget);
    });
  });
}
