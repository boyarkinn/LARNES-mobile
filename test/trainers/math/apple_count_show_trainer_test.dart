import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/math/apple_count_show/apple_count_interactive_scene.dart';
import 'package:larnes_mobile/trainers/math/apple_count_show/apple_count_show_trainer.dart';
import 'package:larnes_mobile/trainers/shared/instruction/trainer_instruction_scene.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';

void main() {
  group('AppleCountShowTrainer', () {
    testWidgets('starts with instruction scene', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 640,
              child: AppleCountShowTrainer(
                params: {
                  'targetCount': 3,
                  'totalApples': 5,
                  'targetDisplay': 'with_digit',
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(TrainerScene), findsOneWidget);
      expect(find.byType(TrainerInstructionScene), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('fills bounded stage', (tester) async {
      const stageKey = Key('apple-stage');

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              key: stageKey,
              width: 320,
              height: 480,
              child: AppleCountShowTrainer(
                params: {
                  'targetCount': 4,
                  'totalApples': 6,
                  'targetDisplay': 'audio_only',
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.getSize(find.byKey(stageKey)), const Size(320, 480));
      expect(tester.getSize(find.byType(TrainerScene)), const Size(320, 480));

      await tester.pump(const Duration(milliseconds: 500));
    });
  });

  group('AppleCountInteractiveScene', () {
    testWidgets('hides target digit in audio_only mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 640,
              child: AppleCountInteractiveScene(
                targetCount: 4,
                totalApples: 6,
                targetDisplay: 'audio_only',
                onComplete: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('4'), findsNothing);
    });
  });
}
