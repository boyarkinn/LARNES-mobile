import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/example_visualization/example_visualization_trainer.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_model.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_widget.dart';
import 'package:larnes_mobile/trainers/shared/instruction/trainer_instruction_scene.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';

Future<void> pumpUntil(
  WidgetTester tester,
  bool Function() reached, {
  int maxSteps = 300,
}) async {
  for (var step = 0; step < maxSteps && !reached(); step++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(reached(), isTrue);
}

int visibleAbacusValue(WidgetTester tester) {
  final widget = tester.widget<AbacusWidget>(find.byType(AbacusWidget));
  return abacusToNumber(widget.rods);
}

Widget exampleTrainer({VoidCallback? onComplete}) => MaterialApp(
  home: Scaffold(
    body: SizedBox(
      width: 360,
      height: 640,
      child: ExampleVisualizationTrainer(
        params: const {
          'example': '+49 +22',
          'stepPauseSec': 0.5,
          'totalRods': 2,
        },
        onComplete: onComplete,
      ),
    ),
  ),
);

void main() {
  testWidgets('uses instruction and shows every abacus gesture', (
    tester,
  ) async {
    await tester.pumpWidget(exampleTrainer());
    await tester.pump();
    expect(find.byType(TrainerScene), findsWidgets);
    expect(find.byType(TrainerInstructionScene), findsOneWidget);

    await pumpUntil(
      tester,
      () => find.byType(AbacusWidget).evaluate().isNotEmpty,
    );
    expect(visibleAbacusValue(tester), 0);
    expect(find.text('+49'), findsOneWidget);

    await pumpUntil(tester, () => visibleAbacusValue(tester) == 49);
    expect(find.text('+49'), findsOneWidget);
    await pumpUntil(tester, () => visibleAbacusValue(tester) == 69);
    expect(find.text('+22'), findsOneWidget);
    await pumpUntil(tester, () => visibleAbacusValue(tester) == 71);
    expect(find.text('+22'), findsOneWidget);
    await pumpUntil(
      tester,
      () => find.byType(TrainerInstructionScene).evaluate().isNotEmpty,
    );
  });

  testWidgets(
    'wrong answer replays the full chain and correct answer completes',
    (tester) async {
      var completions = 0;
      await tester.pumpWidget(exampleTrainer(onComplete: () => completions++));
      await tester.pump();
      await pumpUntil(
        tester,
        () => find.byType(TextField).evaluate().isNotEmpty,
      );
      await tester.enterText(find.byType(TextField), '1');
      await tester.pump();
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNotNull,
      );
      await tester.tap(find.text('Проверить'));
      await tester.pump();
      expect(find.text('Повторить'), findsOneWidget);

      await tester.tap(find.text('Повторить'));
      await tester.pump();
      await pumpUntil(tester, () => find.text('+49').evaluate().isNotEmpty);
      await pumpUntil(tester, () => find.text('+22').evaluate().isNotEmpty);
      await pumpUntil(
        tester,
        () => find.byType(TextField).evaluate().isNotEmpty,
      );
      await tester.enterText(find.byType(TextField), '71');
      await tester.pump();
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNotNull,
      );
      await tester.tap(find.text('Проверить'));
      await pumpUntil(tester, () => completions == 1, maxSteps: 15);
      expect(completions, 1);
    },
  );
}
