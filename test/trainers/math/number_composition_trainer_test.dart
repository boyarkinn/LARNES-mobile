import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/math/number_composition/composition_dot_group.dart';
import 'package:larnes_mobile/trainers/math/number_composition/digit_choice_bar.dart';
import 'package:larnes_mobile/trainers/math/number_composition/dot_choice_bar.dart';
import 'package:larnes_mobile/trainers/math/number_composition/equation_scene.dart';
import 'package:larnes_mobile/trainers/math/number_composition/number_composition_trainer.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';
import 'package:larnes_mobile/trainers/shared/trainer_shell.dart';

void main() {
  group('NumberCompositionTrainer', () {
    testWidgets('uses TrainerScene full-bleed without legacy instruction text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 640,
              child: NumberCompositionTrainer(
                params: {
                  'whole': 5,
                  'knownPart': 2,
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
      expect(find.byType(EquationScene), findsOneWidget);
      expect(find.textContaining('Смотри:'), findsNothing);
      expect(find.textContaining('Сколько'), findsNothing);
      expect(find.textContaining('Молодец'), findsNothing);
      expect(find.text('Дальше'), findsNothing);

      await tester.pump(const Duration(seconds: 12));
    });

    testWidgets('shows dot choice bar in practice-dots phase', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 640,
              child: NumberCompositionTrainer(
                params: {
                  'whole': 4,
                  'knownPart': 1,
                  'answerRangeStart': 0,
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(DotChoiceBar), findsNothing);

      await tester.pump(const Duration(seconds: 12));
      await tester.pump();

      expect(find.byType(DotChoiceBar), findsOneWidget);

      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('fills bounded stage', (tester) async {
      const stageKey = Key('composition-stage');

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              key: stageKey,
              width: 320,
              height: 480,
              child: NumberCompositionTrainer(
                params: {
                  'whole': 3,
                  'knownPart': 1,
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

      await tester.pump(const Duration(seconds: 12));
    });

    testWidgets('equation and choice bar fit portrait width without wrap', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 640,
              child: NumberCompositionTrainer(
                params: {
                  'whole': 2,
                  'knownPart': 1,
                  'answerRangeStart': 0,
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.pump(const Duration(seconds: 12));
      await tester.pump();

      expect(find.byType(CompositionDotGroup), findsWidgets);
      expect(tester.takeException(), isNull);

      final choiceButtons = find.byType(DigitChoiceBar);
      if (choiceButtons.evaluate().isNotEmpty) {
        final textFinder = find.descendant(
          of: choiceButtons,
          matching: find.text('1'),
        );
        if (textFinder.evaluate().isNotEmpty) {
          final textSize = tester.getSize(textFinder.first);
          expect(textSize.height, lessThanOrEqualTo(48));
        }
      }
    });
  });
}
