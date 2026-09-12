import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/catalog/trainer_param_validators.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/flash_cards/flash_cards_trainer.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';
import 'package:larnes_mobile/trainers/shared/trainer_shell.dart';

void main() {
  group('FlashCardsTrainer', () {
    testWidgets('uses TrainerScene full-bleed without legacy TrainerShell', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 640,
              child: FlashCardsTrainer(
                params: {'totalRods': 2, 'values': '10,5,14,2'},
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(TrainerScene), findsOneWidget);
      expect(find.byType(TrainerShell), findsNothing);
    });

    testWidgets('does not render a keyboard answer field', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 640,
              child: FlashCardsTrainer(
                params: {'totalRods': 2, 'values': '12'},
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.byType(TextField), findsNothing);
    });
  });

  group('validateFlashCardsParams', () {
    test('accepts comma-separated values', () {
      final result = validateFlashCardsParams({
        'totalRods': 2,
        'values': '10, 5, 14, 2',
      });

      expect(result.ok, isTrue);
      expect(result.params?['values'], '10,5,14,2');
    });

    test('rejects values above rod capacity', () {
      final result = validateFlashCardsParams({'totalRods': 1, 'values': '12'});

      expect(result.ok, isFalse);
    });
  });
}
