import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/math/fruit_count_tap/fruit_count_tap_trainer.dart';
import 'package:larnes_mobile/trainers/math/fruit_count_tap/fruit_field_scene.dart';
import 'package:larnes_mobile/trainers/shared/numeric_choice_bar.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';
import 'package:larnes_mobile/trainers/shared/trainer_shell.dart';

void main() {
  group('FruitCountTapTrainer', () {
    testWidgets('uses TrainerScene full-bleed without legacy instruction text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 640,
              child: FruitCountTapTrainer(
                params: {
                  'targetFruit': 'watermelon',
                  'targetCount': 3,
                  'totalFruits': 12,
                  'fruitTypeCount': 3,
                  'answerRangeStart': 1,
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(TrainerScene), findsOneWidget);
      expect(find.byType(TrainerShell), findsNothing);
      expect(find.byType(FruitFieldScene), findsOneWidget);
      expect(find.textContaining('Сколько'), findsNothing);
      expect(find.textContaining('Молодец'), findsNothing);

      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('fills bounded stage', (tester) async {
      const stageKey = Key('fruit-stage');

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              key: stageKey,
              width: 320,
              height: 480,
              child: FruitCountTapTrainer(
                params: {
                  'targetFruit': 'apple',
                  'targetCount': 2,
                  'totalFruits': 8,
                  'fruitTypeCount': 2,
                  'answerRangeStart': 0,
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.getSize(find.byKey(stageKey)), const Size(320, 480));
      expect(tester.getSize(find.byType(TrainerScene)), const Size(320, 480));

      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('shows answer bar after fruit reveal completes', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 640,
              child: FruitCountTapTrainer(
                params: {
                  'targetFruit': 'watermelon',
                  'targetCount': 1,
                  'totalFruits': 1,
                  'fruitTypeCount': 1,
                  'answerRangeStart': 0,
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(NumericChoiceBar), findsNothing);

      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();

      expect(find.byType(NumericChoiceBar), findsOneWidget);

      await tester.pump(const Duration(seconds: 2));
    });
  });
}
