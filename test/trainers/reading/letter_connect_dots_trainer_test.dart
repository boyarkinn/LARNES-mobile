import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/reading/letter_connect_dots/connect_dots_scene.dart';
import 'package:larnes_mobile/trainers/reading/letter_connect_dots/letter_connect_dots_trainer.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';
import 'package:larnes_mobile/trainers/shared/trainer_shell.dart';

void main() {
  group('LetterConnectDotsTrainer', () {
    testWidgets('uses TrainerScene full-bleed without legacy instruction text',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 640,
              child: LetterConnectDotsTrainer(
                params: {
                  'letter': 'Е',
                  'letterCase': 'upper',
                  'dotMode': 'numbered',
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(TrainerScene), findsOneWidget);
      expect(find.byType(TrainerShell), findsNothing);
      expect(find.byType(ConnectDotsScene), findsOneWidget);
      expect(find.textContaining('Соедини точки'), findsNothing);
      expect(find.textContaining('Молодец'), findsNothing);

      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('shows check and clear buttons', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 640,
              child: LetterConnectDotsTrainer(
                params: {
                  'letter': 'Е',
                  'letterCase': 'upper',
                  'dotMode': 'free',
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Проверить'), findsOneWidget);
      expect(find.text('Стереть'), findsOneWidget);
    });

    testWidgets('fills bounded stage', (tester) async {
      const stageKey = Key('letter-connect-dots-stage');

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              key: stageKey,
              width: 320,
              height: 480,
              child: LetterConnectDotsTrainer(
                params: {
                  'letter': 'М',
                  'letterCase': 'upper',
                  'dotMode': 'numbered',
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
