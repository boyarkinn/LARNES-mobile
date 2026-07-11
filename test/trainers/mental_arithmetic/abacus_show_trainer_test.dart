import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/abacus_show/abacus_show_trainer.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_widget.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';
import 'package:larnes_mobile/trainers/shared/trainer_shell.dart';

void main() {
  group('AbacusShowTrainer', () {
    testWidgets('uses TrainerScene full-bleed without legacy TrainerShell', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 640,
              child: AbacusShowTrainer(
                params: {
                  'totalRods': 2,
                  'value': 12,
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(TrainerScene), findsOneWidget);
      expect(find.byType(TrainerShell), findsNothing);
      expect(find.byType(AnimatedAbacusValue), findsOneWidget);
      expect(find.byType(AbacusWidget), findsOneWidget);
    });

    testWidgets('fills bounded stage', (tester) async {
      const stageKey = Key('abacus-stage');

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              key: stageKey,
              width: 320,
              height: 480,
              child: AbacusShowTrainer(
                params: {
                  'totalRods': 1,
                  'value': 5,
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
