import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/math/digit_find_tap/digit_field_scene.dart';
import 'package:larnes_mobile/trainers/math/digit_find_tap/digit_find_tap_trainer.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';
import 'package:larnes_mobile/trainers/shared/trainer_shell.dart';

void main() {
  group('DigitFindTapTrainer', () {
    testWidgets('uses TrainerScene full-bleed without legacy instruction text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 640,
              child: DigitFindTapTrainer(
                params: {
                  'digit': 5,
                  'targetCount': 3,
                  'distractorCount': 10,
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(TrainerScene), findsOneWidget);
      expect(find.byType(TrainerShell), findsNothing);
      expect(find.byType(DigitFieldScene), findsOneWidget);
      expect(find.textContaining('Найди'), findsNothing);
      expect(find.textContaining('Молодец'), findsNothing);
      expect(find.textContaining('/'), findsNothing);

      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('fills bounded stage', (tester) async {
      const stageKey = Key('digit-stage');

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              key: stageKey,
              width: 320,
              height: 480,
              child: DigitFindTapTrainer(
                params: {
                  'digit': 2,
                  'targetCount': 2,
                  'distractorCount': 6,
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

    testWidgets('replays snapshot-seeded digits and placement', (tester) async {
      Future<List<Object>> buildSignature() async {
        await tester.pumpWidget(
          const MaterialApp(
            home: SizedBox(
              width: 360,
              height: 640,
              child: DigitFindTapTrainer(
                params: {
                  'digit': 2,
                  'targetCount': 3,
                  'distractorCount': 8,
                  '__runtimeSnapshot': {
                    'version': 1,
                    'trainerKey': 'digit-find-tap',
                    'mode': 'materialized',
                    'payload': {'seed': 20260827},
                  },
                },
              ),
            ),
          ),
        );
        await tester.pump();

        final digits = tester.widget<DigitFieldScene>(
          find.byType(DigitFieldScene),
        ).digits;
        return [
          for (final digit in digits)
            [
              digit.id,
              digit.digit,
              digit.isTarget,
              digit.xPercent,
              digit.yPercent,
            ],
        ];
      }

      final first = await buildSignature();
      await tester.pumpWidget(const SizedBox.shrink());
      final second = await buildSignature();

      expect(second, first);
      await tester.pump(const Duration(seconds: 3));
    });
  });
}
