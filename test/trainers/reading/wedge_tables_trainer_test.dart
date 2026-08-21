import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/reading/wedge_tables/wedge_tables_scene.dart';
import 'package:larnes_mobile/trainers/reading/wedge_tables/wedge_tables_trainer.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';
import 'package:larnes_mobile/trainers/shared/trainer_shell.dart';

void main() {
  group('WedgeTablesTrainer', () {
    testWidgets('uses a full-bleed scene without instruction text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 640,
              child: WedgeTablesTrainer(
                params: {
                  'category': 'digits',
                  'displaySeconds': 2,
                  'orientation': 'horizontal',
                  'rounds': 1,
                  'rowCount': 5,
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(TrainerScene), findsOneWidget);
      expect(find.byType(TrainerShell), findsNothing);
      expect(find.textContaining('Найди'), findsNothing);
      expect(find.textContaining('Молодец'), findsNothing);
      expect(find.textContaining('Готово'), findsNothing);
      expect(find.byType(ElevatedButton), findsNothing);
      expect(find.byType(TextButton), findsNothing);

      await tester.pump(const Duration(milliseconds: 400));
    });

    testWidgets('fills bounded stage', (tester) async {
      const stageKey = Key('wedge-tables-stage');

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              key: stageKey,
              width: 320,
              height: 480,
              child: WedgeTablesTrainer(
                params: {
                  'category': 'digits',
                  'displaySeconds': 2,
                  'orientation': 'vertical',
                  'rounds': 1,
                  'rowCount': 5,
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.getSize(find.byKey(stageKey)), const Size(320, 480));
      expect(tester.getSize(find.byType(TrainerScene)), const Size(320, 480));
      expect(find.byType(WedgeTablesScene), findsNothing);

      await tester.pump(const Duration(milliseconds: 400));
    });
  });
}
