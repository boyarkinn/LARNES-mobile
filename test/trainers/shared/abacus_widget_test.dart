import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_geometry.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_model.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_painter.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_widget.dart';

void main() {
  test('red marker bead keeps its color after moving up', () async {
    Future<ui.Color> markerColor(int earthCount) async {
      final rods = [
        RodState(heavenUp: false, earthCount: earthCount),
        ...emptyRods(2),
      ];
      final layout = layoutsForRods(rods);
      final viewBox = abacusViewBox(3);
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      AbacusPainter(
        rodLayouts: layout,
        rods: rods,
        totalRods: 3,
      ).paint(canvas, ui.Size(viewBox.width, viewBox.height));
      final picture = recorder.endRecording();
      final image = await picture.toImage(
        viewBox.width.ceil(),
        viewBox.height.ceil(),
      );
      picture.dispose();
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      final x = rodCenterX(0).round();
      final y = layout[0].earthYs[0].round();
      final offset = (y * image.width + x) * 4;
      final color = ui.Color.fromARGB(
        data!.getUint8(offset + 3),
        data.getUint8(offset),
        data.getUint8(offset + 1),
        data.getUint8(offset + 2),
      );
      image.dispose();
      return color;
    }

    final resting = await markerColor(0);
    final raised = await markerColor(1);
    expect(raised.r, closeTo(resting.r, .01));
    expect(raised.g, closeTo(resting.g, .01));
    expect(raised.b, closeTo(resting.b, .01));
    expect(resting.r, greaterThan(resting.g * 2));
    expect(resting.r, greaterThan(resting.b * 2));
  });

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
