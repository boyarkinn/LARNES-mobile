import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/dots_digit_abacus/dots_digit_abacus_trainer.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/dots_digit_abacus/triple_scene.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_widget.dart';
import 'package:larnes_mobile/trainers/shared/dot_group.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';
import 'package:larnes_mobile/trainers/shared/trainer_shell.dart';

void main() {
  group('DotsDigitAbacusTrainer', () {
    testWidgets('uses TrainerScene full-bleed without legacy instruction text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 640,
              child: DotsDigitAbacusTrainer(
                params: {
                  'totalRods': 2,
                  'value': 3,
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(TrainerScene), findsOneWidget);
      expect(find.byType(TrainerShell), findsNothing);
      expect(find.byType(TripleScene), findsOneWidget);
      expect(find.byType(DotGroup), findsOneWidget);
      expect(find.byType(AbacusWidget), findsOneWidget);
      expect(find.textContaining('Смотри:'), findsNothing);
    });

    testWidgets('fills bounded stage', (tester) async {
      const stageKey = Key('dots-stage');

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              key: stageKey,
              width: 320,
              height: 480,
              child: DotsDigitAbacusTrainer(
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

    testWidgets('keeps digit inside its card in portrait', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 640,
              child: DotsDigitAbacusTrainer(
                params: {
                  'totalRods': 1,
                  'value': 2,
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 1200));

      final cardSize = tester.getSize(find.byKey(const Key('triple-digit-card')));
      final digitSize = tester.getSize(find.text('2'));

      expect(digitSize.width, lessThanOrEqualTo(cardSize.width));
      expect(digitSize.height, lessThanOrEqualTo(cardSize.height));
    });
  });
}
