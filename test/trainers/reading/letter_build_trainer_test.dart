import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/math/digit_find_tap/digit_found_burst.dart';
import 'package:larnes_mobile/trainers/reading/letter_build/build_scene.dart';
import 'package:larnes_mobile/trainers/reading/letter_build/build_reveal.dart';
import 'package:larnes_mobile/trainers/reading/letter_build/letter_build_model.dart';
import 'package:larnes_mobile/trainers/reading/letter_build/letter_build_trainer.dart';
import 'package:larnes_mobile/trainers/reading/zaitsev/path_geometry.dart';
import 'package:larnes_mobile/trainers/reading/zaitsev/zaitsev_sticks.dart' show getBuildLayout;
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';
import 'package:larnes_mobile/trainers/shared/trainer_shell.dart';
import 'package:larnes_mobile/trainers/shared/trainer_timings.dart';

void main() {
  group('LetterBuildTrainer', () {
    testWidgets('uses TrainerScene full-bleed without legacy instruction text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 640,
              child: LetterBuildTrainer(
                params: {
                  'letter': 'ё',
                  'letterCase': 'lower',
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(TrainerScene), findsOneWidget);
      expect(find.byType(TrainerShell), findsNothing);
      expect(find.byType(BuildScene), findsOneWidget);
      final scene = tester.widget<BuildScene>(find.byType(BuildScene));
      expect(scene.guideLetter, 'Ё');
      expect(scene.displayLetter, 'ё');
      expect(find.textContaining('Сначала собери'), findsNothing);
      expect(find.textContaining('Положи все палочки'), findsNothing);
      expect(find.textContaining('Молодец'), findsNothing);

      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('finishes once after guided assembly without a second stage', (tester) async {
      var completed = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 640,
              child: LetterBuildTrainer(
                params: const {
                  'letter': 'О',
                  'letterCase': 'lower',
                },
                onComplete: () => completed++,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Проверить'), findsNothing);
      expect(find.text('Стереть'), findsNothing);

      final piece = getPiecesForLetter('О').single;
      await tester.pump(Duration(
        milliseconds: getBuildInteractionReadyMs(1) + 10,
      ));
      final scene = tester.widget<BuildScene>(find.byType(BuildScene));
      final pad = find.descendant(
        of: find.byType(BuildScene),
        matching: find.byType(Listener),
      );
      final size = tester.getSize(pad);
      final layout = getBuildLayout('О')!;
      final scale = size.width / layout.width;
      final sample = sampleSvgPath(piece.path).first;
      final start = tester.getTopLeft(pad) + Offset(
        ((sample.x + piece.paletteOffset.x) * zaitsevCoordSize - layout.minX) * scale,
        ((sample.y + piece.paletteOffset.y) * zaitsevCoordSize - layout.minY) * scale,
      );
      await tester.dragFrom(start, Offset(
        -piece.paletteOffset.x * zaitsevCoordSize * scale,
        -piece.paletteOffset.y * zaitsevCoordSize * scale,
      ));
      await tester.pump();

      expect(find.byType(DigitFoundBurst), findsOneWidget);
      expect(completed, 0);
      expect(tester.widget<BuildScene>(find.byType(BuildScene)), same(scene));
      expect(find.text('Проверить'), findsNothing);
      expect(find.text('Стереть'), findsNothing);

      await tester.pump(const Duration(
        milliseconds: TrainerTimings.completeAfterBurstMs,
      ));
      expect(completed, 1);
      await tester.pump(const Duration(seconds: 1));
      expect(completed, 1);
    });

    testWidgets('fills bounded stage', (tester) async {
      const stageKey = Key('letter-build-stage');

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              key: stageKey,
              width: 320,
              height: 480,
              child: LetterBuildTrainer(
                params: {
                  'letter': 'М',
                  'letterCase': 'upper',
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
