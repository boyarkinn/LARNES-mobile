import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/static_example_show/static_example_geometry.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_geometry.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_material.dart';

/// Web v2: monochrome abacus + move overlays (`static-example-show/geometry.ts`).
abstract final class StaticAbacusColors {
  static const bar = Color(0xFF525252);
  static const beadFill = Color(0xFFFFFFFF);
  static const beadStroke = Color(0xFF1A1A1A);
  static const rod = Color(0xFFC4C4C4);
  static const overlayAdd = Color(0x7322C55E);
  static const overlaySubtract = Color(0x73EF4444);
  static const overlayStroke = Color(0xFF1A1A1A);
  static const arrow = Color(0xFF1A1A1A);
}

class StaticAbacusPainter extends CustomPainter {
  StaticAbacusPainter({
    required this.rodLayouts,
    required this.totalRods,
    required this.viewBox,
    this.overlayLayouts = const [],
  });

  final List<RodBeadLayout> rodLayouts;
  final int totalRods;
  final StaticAbacusViewBoxMetrics viewBox;
  final List<MoveOverlayLayout> overlayLayouts;
  final _material = AbacusMaterialPainter(monochrome: true);

  static const _arrowStroke = 1.75;
  static const _arrowHeadHalf = 3.5;
  static const _arrowEdgeInset = 7.0;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(-viewBox.viewBoxX, 0);

    final base = viewBox.base;

    for (final layout in overlayLayouts) {
      _paintMoveOverlay(canvas, layout);
    }

    _material.paintRails(canvas, base);

    for (var rodIndex = 0; rodIndex < rodLayouts.length; rodIndex++) {
      _material.paintRod(canvas, rodIndex, base);
    }

    _material.paintBars(canvas, base);

    for (var rodIndex = 0; rodIndex < rodLayouts.length; rodIndex++) {
      _paintRodBeads(canvas, rodIndex, rodLayouts[rodIndex]);
    }

    canvas.restore();
  }

  void _paintMoveOverlay(Canvas canvas, MoveOverlayLayout layout) {
    final fillColor = layout.polarity == 'add'
        ? StaticAbacusColors.overlayAdd
        : StaticAbacusColors.overlaySubtract;

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(layout.x, layout.y, layout.width, layout.height),
      const Radius.circular(2),
    );

    canvas.drawRRect(rect, Paint()..color = fillColor);
    _paintDashedRRect(
      canvas,
      rect,
      Paint()
        ..color = StaticAbacusColors.overlayStroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    _paintVerticalArrow(
      canvas,
      centerX: layout.x + layout.arrowX,
      direction: layout.arrowDirection,
      topY: layout.y,
      height: layout.height,
    );
  }

  void _paintVerticalArrow(
    Canvas canvas, {
    required double centerX,
    required String direction,
    required double topY,
    required double height,
  }) {
    final paint = Paint()
      ..color = StaticAbacusColors.arrow
      ..strokeWidth = _arrowStroke
      ..strokeCap = StrokeCap.round;

    final headBaseOffset = _arrowEdgeInset + _arrowHeadHalf;

    if (direction == 'up') {
      final tipY = topY + _arrowEdgeInset;
      final headBaseY = topY + headBaseOffset;
      final tailY = topY + height - _arrowEdgeInset;

      canvas.drawLine(
        Offset(centerX, tailY),
        Offset(centerX, headBaseY),
        paint,
      );

      final headPath = Path()
        ..moveTo(centerX - _arrowHeadHalf, headBaseY)
        ..lineTo(centerX, tipY)
        ..lineTo(centerX + _arrowHeadHalf, headBaseY)
        ..close();

      canvas.drawPath(headPath, paint..style = PaintingStyle.fill);
      return;
    }

    final tipY = topY + height - _arrowEdgeInset;
    final headBaseY = topY + height - headBaseOffset;
    final tailY = topY + _arrowEdgeInset;

    canvas.drawLine(Offset(centerX, tailY), Offset(centerX, headBaseY), paint);

    final headPath = Path()
      ..moveTo(centerX - _arrowHeadHalf, headBaseY)
      ..lineTo(centerX, tipY)
      ..lineTo(centerX + _arrowHeadHalf, headBaseY)
      ..close();

    canvas.drawPath(headPath, paint..style = PaintingStyle.fill);
  }

  void _paintRodBeads(Canvas canvas, int rodIndex, RodBeadLayout beadLayout) {
    final cx = rodCenterX(rodIndex);

    _material.paintBead(canvas, cx, beadLayout.heavenY);

    for (final earthY in beadLayout.earthYs) {
      _material.paintBead(canvas, cx, earthY);
    }
  }

  @override
  bool shouldRepaint(covariant StaticAbacusPainter oldDelegate) {
    return oldDelegate.rodLayouts != rodLayouts ||
        oldDelegate.totalRods != totalRods ||
        oldDelegate.viewBox != viewBox ||
        oldDelegate.overlayLayouts != overlayLayouts;
  }
}

void _paintDashedRRect(Canvas canvas, RRect rrect, Paint paint) {
  const dashLength = 4.0;
  const gapLength = 3.0;
  final path = Path()..addRRect(rrect);

  for (final metric in path.computeMetrics()) {
    var distance = 0.0;
    while (distance < metric.length) {
      final end = distance + dashLength;
      canvas.drawPath(
        metric.extractPath(distance, end.clamp(0, metric.length)),
        paint,
      );
      distance = end + gapLength;
    }
  }
}
