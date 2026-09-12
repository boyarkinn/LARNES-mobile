import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/catalog/trainer_direction.dart';
import 'package:larnes_mobile/trainers/shared/instruction/trainer_instruction_scene.dart';
import 'package:larnes_mobile/trainers/shared/instruction/trainer_instruction_typewriter.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';
import 'package:larnes_mobile/trainers/shared/theme/trainer_direction_theme.dart';

void main() {
  group('trainer instruction shared', () {
    testWidgets('keeps fallback colors outside direction scope', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 640,
              child: TrainerInstructionScene(
                length: 6,
                text:
                    'Отследи движение мухи и нажми на поле, где она приземлилась.',
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(TrainerScene), findsOneWidget);
      expect(find.textContaining('Отслед'), findsOneWidget);
      expect(find.textContaining('приземлилась'), findsNothing);
      expect(_instructionTextColor(tester), kTrainerInstructionColor);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.color == kTrainerInstructionCursorColor,
        ),
        findsOneWidget,
      );
    });

    testWidgets('uses scoped direction colors for text and cursor', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TrainerDirectionThemeScope(
            direction: TrainerDirection.math,
            child: SizedBox(
              width: 360,
              height: 640,
              child: TrainerInstructionScene(
                length: 6,
                text: 'Посчитай предметы.',
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final theme = trainerDirectionThemes[TrainerDirection.math]!;
      expect(_instructionTextColor(tester), theme.deep);
      expect(
        find.byWidgetPredicate(
          (widget) => widget is Container && widget.color == theme.base,
        ),
        findsOneWidget,
      );
    });

    test('typewriter advances one character per tick', () {
      final lengths = <int>[];
      final typewriter = TrainerInstructionTypewriter();

      typewriter.start(
        text: 'абв',
        durationMs: 30,
        isCurrent: () => true,
        onLength: lengths.add,
      );

      expect(lengths, [0]);
      typewriter.cancel();
    });
  });
}

Color? _instructionTextColor(WidgetTester tester) {
  final text = tester.widget<Text>(
    find.byWidgetPredicate(
      (widget) => widget is Text && widget.textSpan != null,
    ),
  );
  final rootSpan = text.textSpan as TextSpan;
  return (rootSpan.children!.first as TextSpan).style?.color;
}
