import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/shared/instruction/trainer_instruction_scene.dart';
import 'package:larnes_mobile/trainers/shared/instruction/trainer_instruction_typewriter.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';

void main() {
  group('trainer instruction shared', () {
    testWidgets('uses the fly teal typewriter scene', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 640,
              child: TrainerInstructionScene(
                length: 6,
                text: 'Отследи движение мухи и нажми на поле, где она приземлилась.',
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(TrainerScene), findsOneWidget);
      expect(find.textContaining('Отслед'), findsOneWidget);
      expect(find.textContaining('приземлилась'), findsNothing);
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
