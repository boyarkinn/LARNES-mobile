import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/reading/schulte_table/model.dart';
import 'package:larnes_mobile/trainers/reading/schulte_table/schulte_table_scene.dart';
import 'package:larnes_mobile/trainers/reading/schulte_table/schulte_table_trainer.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';
import 'package:larnes_mobile/trainers/shared/trainer_shell.dart';

void main() {
  group('SchulteTableTrainer', () {
    testWidgets('uses a full-bleed scene without instruction text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 640,
              child: SchulteTableTrainer(
                params: {
                  'category': 'digits',
                  'gridSize': 3,
                  'order': 'forward',
                  'rounds': 1,
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
      expect(find.byType(SchulteTableScene), findsNothing);
    });

    testWidgets('fills bounded stage', (tester) async {
      const stageKey = Key('schulte-table-stage');

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              key: stageKey,
              width: 320,
              height: 480,
              child: SchulteTableTrainer(
                params: {
                  'category': 'digits',
                  'gridSize': 3,
                  'order': 'forward',
                  'rounds': 1,
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.getSize(find.byKey(stageKey)), const Size(320, 480));
      expect(tester.getSize(find.byType(TrainerScene)), const Size(320, 480));
      expect(find.byType(SchulteTableScene), findsNothing);
    });
  });

  group('SchulteTableScene', () {
    testWidgets('advances on the next cell and shakes a wrong tap', (tester) async {
      final table = generateSchulteTable(
        const GenerateSchulteTableInput(
          category: 'digits',
          gridSize: 3,
          order: 'forward',
          random: _zero,
        ),
      );
      final tapped = <String>[];
      var wrongCellId = '';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 640,
              child: StatefulBuilder(
                builder: (context, setState) {
                  return SchulteTableScene(
                    disabled: false,
                    foundValues: tapped.toSet(),
                    onCellTap: (cell) {
                      if (isNextSchulteTarget(cell.value, table.sequence, tapped.length)) {
                        setState(() => tapped.add(cell.value));
                      } else {
                        setState(() => wrongCellId = schulteCellId(cell));
                      }
                    },
                    showCenterDot: false,
                    showFound: true,
                    symbolOrientation: 'normal',
                    table: table,
                    wrongCellId: wrongCellId,
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('2'));
      await tester.pump();
      expect(tapped, isEmpty);
      expect(wrongCellId, isNotEmpty);

      await tester.tap(find.text('1'));
      await tester.pump();
      expect(tapped, ['1']);
    });
  });
}

double _zero() => 0;
