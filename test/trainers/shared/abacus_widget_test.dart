import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_geometry.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_model.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_painter.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_widget.dart';

void main() {
  testWidgets(
    'custom bead duration animates positions then reaches the target',
    (tester) async {
      var rods = emptyRods(1);
      late StateSetter update;
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return AbacusWidget(
                rods: rods,
                totalRods: 1,
                beadAnimationDuration: const Duration(milliseconds: 333),
              );
            },
          ),
        ),
      );

      List<RodBeadLayout> displayed() =>
          (tester
                      .widget<CustomPaint>(
                        find.descendant(
                          of: find.byType(AbacusWidget),
                          matching: find.byType(CustomPaint),
                        ),
                      )
                      .painter!
                  as AbacusPainter)
              .rodLayouts;

      final target = layoutsForRods(numberToAbacus(4, 1)).single;
      update(() => rods = numberToAbacus(4, 1));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(displayed().single.earthYs, isNot(target.earthYs));
      await tester.pump(const Duration(milliseconds: 233));
      expect(displayed().single.earthYs, target.earthYs);
    },
  );

  testWidgets('reduced motion paints the target bead positions immediately', (
    tester,
  ) async {
    var rods = emptyRods(2);
    late StateSetter update;

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return AbacusWidget(rods: rods, totalRods: 2);
            },
          ),
        ),
      ),
    );

    update(() => rods = numberToAbacus(49, 2));
    await tester.pump();

    final paint = tester.widget<CustomPaint>(
      find.descendant(
        of: find.byType(AbacusWidget),
        matching: find.byType(CustomPaint),
      ),
    );
    final actual = (paint.painter! as AbacusPainter).rodLayouts;
    final expected = layoutsForRods(numberToAbacus(49, 2));
    for (var index = 0; index < expected.length; index++) {
      expect(actual[index].heavenY, expected[index].heavenY);
      expect(actual[index].earthYs, expected[index].earthYs);
    }
  });
}
