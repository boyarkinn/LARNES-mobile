import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/math/apple_count_show/apple_count_scene.dart';
import 'package:larnes_mobile/trainers/math/apple_count_show/apple_count_show_trainer.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';
import 'package:larnes_mobile/trainers/shared/trainer_shell.dart';

void main() {
  group('AppleCountShowTrainer', () {
    testWidgets('uses TrainerScene full-bleed without legacy digit or empty text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 640,
              child: AppleCountShowTrainer(
                params: {'digit': 4},
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(TrainerScene), findsOneWidget);
      expect(find.byType(TrainerShell), findsNothing);
      expect(find.byType(AppleCountScene), findsOneWidget);
      expect(find.text('4'), findsNothing);
      expect(find.textContaining('корзинке'), findsNothing);

      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('shows empty basket scene for digit zero', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 640,
              child: AppleCountShowTrainer(
                params: {'digit': 0},
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(AppleCountScene), findsOneWidget);
      expect(find.textContaining('пусто'), findsNothing);
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
                params: {'digit': 3},
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
}
