import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/static_example_show/move_hints.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/static_example_show/static_abacus_painter.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/static_example_show/static_example_geometry.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_geometry.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_model.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_painter.dart';

void main() {
  test('full frame fits existing bounds and leaves bead clearance', () async {
    for (final totalRods in [1, 3, 13]) {
      final rods = emptyRods(totalRods);
      final viewBox = abacusViewBox(totalRods);
      final raster = await _render(
        AbacusPainter(
          rodLayouts: layoutsForRods(rods),
          rods: rods,
          totalRods: totalRods,
        ),
        Size(viewBox.width, viewBox.height),
      );
      addTearDown(raster.image.dispose);

      for (final x in [2.0, viewBox.width - 2]) {
        final rail = raster.pixel(x, 40);
        expect(rail.r, greaterThan(rail.g));
        expect(rail.g, greaterThan(rail.b));
      }
      expect(raster.pixel(AbacusLayout.sideInset + 1, 40), Colors.white);
      expect(
        raster.pixel(viewBox.width - AbacusLayout.sideInset - 1, 40),
        Colors.white,
      );
      final firstBeadLeft = rodCenterX(0) - AbacusLayout.beadHalfWidth;
      expect(firstBeadLeft - AbacusLayout.sideInset, closeTo(2.2, .00001));
      expect(raster.pixel(rodCenterX(0), 40), isNot(Colors.white));
      expect(raster.pixel(rodCenterX(0) + 1.2, 40), Colors.white);
      expect(
        raster.pixel(2, viewBox.bottomBarY + AbacusLayout.barHeight + 2),
        Colors.white,
      );
    }
  });

  test(
    'ivory and marker beads have a lit upper and shaded lower facet',
    () async {
      final rods = emptyRods(3);
      final layouts = layoutsForRods(rods);
      final viewBox = abacusViewBox(3);
      final raster = await _render(
        AbacusPainter(rodLayouts: layouts, rods: rods, totalRods: 3),
        Size(viewBox.width, viewBox.height),
      );
      addTearDown(raster.image.dispose);

      for (final rod in [0, 1]) {
        final y = layouts[rod].earthYs.first;
        final upper = raster.pixel(rodCenterX(rod), y - 4);
        final lower = raster.pixel(rodCenterX(rod), y + 4);
        expect(upper.computeLuminance(), greaterThan(lower.computeLuminance()));
        if (rod == 0) {
          expect(upper.r, greaterThan(upper.g * 2));
          expect(lower.r, greaterThan(lower.g * 2));
        } else {
          expect((upper.r - upper.g).abs(), lessThan(.03));
          expect((lower.r - lower.g).abs(), lessThan(.03));
        }
      }
    },
  );

  test(
    'movement colors override active color and the persistent marker',
    () async {
      final rods = [
        const RodState(heavenUp: true, earthCount: 3),
        ...emptyRods(2),
      ];
      final layouts = layoutsForRods(rods);
      final viewBox = abacusViewBox(3);
      final raster = await _render(
        AbacusPainter(
          rodLayouts: layouts,
          rods: rods,
          totalRods: 3,
          activeBeadColor: Colors.blue,
          raisingBeadColor: Colors.green,
          loweringBeadColor: Colors.purple,
          movingBeadHighlights: const [
            RodMovingBeadHighlight(
              heaven: BeadMoveDirection.lower,
              raisingEarthIndices: {0},
              loweringEarthIndices: {1},
            ),
            RodMovingBeadHighlight(),
            RodMovingBeadHighlight(),
          ],
        ),
        Size(viewBox.width, viewBox.height),
      );
      addTearDown(raster.image.dispose);
      final cx = rodCenterX(0);
      final raisedMarker = raster.pixel(cx, layouts[0].earthYs[0] + 3);
      final lowering = raster.pixel(cx, layouts[0].earthYs[1] + 3);
      final active = raster.pixel(cx, layouts[0].earthYs[2] + 3);
      final heaven = raster.pixel(cx, layouts[0].heavenY + 3);
      expect(raisedMarker.g, greaterThan(raisedMarker.r * 1.5));
      expect(raisedMarker.g, greaterThan(raisedMarker.b * 1.5));
      expect(lowering.r, greaterThan(lowering.g * 1.5));
      expect(lowering.b, greaterThan(lowering.g * 1.5));
      expect(heaven, lowering);
      expect(active.b, greaterThan(active.r * 1.5));
      expect(active.b, greaterThan(active.g));
    },
  );

  test(
    'static material keeps monochrome beads and visible instructional overlays',
    () async {
      final monochromeRods = numberToAbacus(100, 3);
      final monochromeViewBox = abacusViewBoxWithMoveOverlays(
        3,
        const [],
        monochromeRods,
      );
      final monochromeLayouts = layoutsForRods(monochromeRods);
      final monochrome = await _render(
        StaticAbacusPainter(
          rodLayouts: monochromeLayouts,
          totalRods: 3,
          viewBox: monochromeViewBox,
        ),
        Size(monochromeViewBox.viewBoxWidth, monochromeViewBox.base.height),
      );
      addTearDown(monochrome.image.dispose);
      final markerPosition = monochrome.pixel(
        rodCenterX(0),
        monochromeLayouts[0].earthYs[0] + 3,
      );
      expect((markerPosition.r - markerPosition.g).abs(), lessThan(.03));
      expect((markerPosition.g - markerPosition.b).abs(), lessThan(.03));

      final rods = numberToAbacus(10, 2);
      final moves = resolveMoveOverlays(
        operation: 'subtract',
        operandA: 10,
        operandB: 9,
        totalRods: 2,
      );
      final viewBox = abacusViewBoxWithMoveOverlays(2, moves, rods);
      final overlays = layoutMoveOverlays(moves, rods, 2);
      final layouts = layoutsForRods(rods);
      final raster = await _render(
        StaticAbacusPainter(
          rodLayouts: layouts,
          totalRods: 2,
          viewBox: viewBox,
          overlayLayouts: overlays,
        ),
        Size(viewBox.viewBoxWidth, viewBox.base.height),
      );
      addTearDown(raster.image.dispose);
      for (final overlay in overlays) {
        final arrow = raster.pixel(
          overlay.x + overlay.arrowX - viewBox.viewBoxX,
          overlay.y + overlay.height / 2,
        );
        expect(arrow.computeLuminance(), lessThan(.15));
        final color = raster.pixel(
          overlay.x + overlay.arrowX + 2 - viewBox.viewBoxX,
          overlay.y + overlay.height / 2,
        );
        if (overlay.polarity == 'add') {
          expect(color.g, greaterThan(color.r));
        } else {
          expect(color.r, greaterThan(color.g));
        }
      }
    },
  );

  test('renders material overview for optional visual review', () async {
    const path = String.fromEnvironment('ABACUS_MATERIAL_PREVIEW');
    if (path.isEmpty) return;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawColor(Colors.white, BlendMode.src);
    canvas.scale(3);
    canvas.translate(12, 0);
    var y = 0.0;
    for (final count in [3, 13]) {
      final rods = numberToAbacus(1234567890123, count);
      final viewBox = abacusViewBox(count);
      canvas.save();
      canvas.translate(0, y);
      AbacusPainter(
        rodLayouts: layoutsForRods(rods),
        rods: rods,
        totalRods: count,
      ).paint(canvas, Size(viewBox.width, viewBox.height));
      canvas.restore();
      y += viewBox.height + 6;
    }
    final rods = numberToAbacus(10, 2);
    final moves = resolveMoveOverlays(
      operation: 'subtract',
      operandA: 10,
      operandB: 9,
      totalRods: 2,
    );
    final viewBox = abacusViewBoxWithMoveOverlays(2, moves, rods);
    canvas.translate(0, y);
    StaticAbacusPainter(
      rodLayouts: layoutsForRods(rods),
      totalRods: 2,
      viewBox: viewBox,
      overlayLayouts: layoutMoveOverlays(moves, rods, 2),
    ).paint(canvas, Size(viewBox.viewBoxWidth, viewBox.base.height));
    final picture = recorder.endRecording();
    final image = await picture.toImage(1400, 1500);
    picture.dispose();
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    await File(path).writeAsBytes(png!.buffer.asUint8List());
  });
}

Future<_Raster> _render(CustomPainter painter, Size size) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawColor(Colors.white, BlendMode.src);
  canvas.scale(_Raster.scale);
  painter.paint(canvas, size);
  final picture = recorder.endRecording();
  final image = await picture.toImage(
    (size.width * _Raster.scale).ceil(),
    (size.height * _Raster.scale).ceil(),
  );
  picture.dispose();
  return _Raster(
    image,
    (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!,
  );
}

class _Raster {
  const _Raster(this.image, this.data);

  static const scale = 4.0;
  final ui.Image image;
  final ByteData data;

  Color pixel(double x, double y) {
    final offset =
        ((y * scale).round() * image.width + (x * scale).round()) * 4;
    return Color.fromARGB(
      data.getUint8(offset + 3),
      data.getUint8(offset),
      data.getUint8(offset + 1),
      data.getUint8(offset + 2),
    );
  }
}
