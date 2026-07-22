import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/example_visualization/example_visualization_trainer.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_widget.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';

void main() {
  group('ExampleVisualizationTrainer', () {
    testWidgets('uses TrainerScene and abacus widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 640,
              child: ExampleVisualizationTrainer(
                params: {
                  'example': '+2 -1',
                  'stepPauseSec': 0.5,
                  'totalRods': 1,
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(TrainerScene), findsOneWidget);
      expect(find.byType(AbacusWidget), findsOneWidget);
      expect(find.text('+2'), findsOneWidget);
    });

    testWidgets('autoplay advances action label and holds final state', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 640,
              child: ExampleVisualizationTrainer(
                params: {
                  'example': '+2 -1',
                  'stepPauseSec': 0.5,
                  'totalRods': 1,
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('+2'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('-1'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      expect(find.text('-1'), findsNothing);
      expect(find.byType(AbacusWidget), findsOneWidget);
    });
  });
}
