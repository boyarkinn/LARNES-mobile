import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/reading/letter_marquee_tap/letter_marquee_tap_trainer.dart';
import 'package:larnes_mobile/trainers/reading/letter_marquee_tap/marquee_progress_dots.dart';
import 'package:larnes_mobile/trainers/reading/letter_marquee_tap/marquee_scene.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';
import 'package:larnes_mobile/trainers/shared/trainer_shell.dart';

void main() {
  group('LetterMarqueeTapTrainer', () {
    testWidgets('uses TrainerScene full-bleed without legacy instruction text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 640,
              child: LetterMarqueeTapTrainer(
                params: {
                  'practiceLetters': 'А, М, К',
                  'targetCount': 5,
                  'letterCase': 'upper',
                  'speed': 'medium',
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(TrainerScene), findsOneWidget);
      expect(find.byType(TrainerShell), findsNothing);
      expect(find.byType(MarqueeScene), findsOneWidget);
      expect(find.byType(MarqueeProgressDots), findsOneWidget);
      expect(find.textContaining('Бегущая'), findsNothing);
      expect(find.textContaining('Молодец'), findsNothing);
      expect(find.textContaining('0/'), findsNothing);

      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('fills bounded stage', (tester) async {
      const stageKey = Key('letter-marquee-tap-stage');

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              key: stageKey,
              width: 320,
              height: 480,
              child: LetterMarqueeTapTrainer(
                params: {
                  'practiceLetters': 'А, Б',
                  'targetCount': 3,
                  'letterCase': 'upper',
                  'speed': 'slow',
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
  });
}
