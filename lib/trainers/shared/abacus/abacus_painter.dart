import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_geometry.dart';

abstract final class AbacusColors {
  static const bar = Color(0xFF6B5344);
  static const beadFill = Color(0xFFFFFCF8);
  static const beadMarkerFill = Color(0xFFE53935);
  static const beadStroke = Color(0xFF5C4D3D);
  static const rod = Color(0xFFC9B8A8);
}

class AbacusPainter extends CustomPainter {
  AbacusPainter({
    required this.rodLayouts,
    required this.totalRods,
  });

  final List<RodBeadLayout> rodLayouts;
  final int totalRods;

  @override
  void paint(Canvas canvas, Size size) {
    final viewBox = abacusViewBox(totalRods);
    final barWidth = viewBox.width - AbacusLayout.sideInset * 2;
    final barX = AbacusLayout.sideInset;
    final rodLineBottomY = rodBottomY(viewBox.bottomBarY);

    for (var rodIndex = 0; rodIndex < rodLayouts.length; rodIndex++) {
      _paintRodLine(canvas, rodIndex, rodLineBottomY);
    }

    canvas.drawRect(
      Rect.fromLTWH(barX, viewBox.topBarY, barWidth, AbacusLayout.barHeight),
      Paint()..color = AbacusColors.bar,
    );
    canvas.drawRect(
      Rect.fromLTWH(barX, viewBox.beamY, barWidth, AbacusLayout.barHeight),
      Paint()..color = AbacusColors.bar,
    );
    canvas.drawRect(
      Rect.fromLTWH(barX, viewBox.bottomBarY, barWidth, AbacusLayout.barHeight),
      Paint()..color = AbacusColors.bar,
    );

    for (var rodIndex = 0; rodIndex < rodLayouts.length; rodIndex++) {
      _paintRodBeads(canvas, rodIndex, rodLayouts[rodIndex]);
    }
  }

  void _paintRodLine(Canvas canvas, int rodIndex, double bottomY) {
    final cx = rodCenterX(rodIndex);

    final edgePaint = Paint()
      ..color = AbacusColors.beadStroke
      ..strokeWidth = AbacusLayout.rodEdgeStrokeWidth
      ..strokeCap = StrokeCap.round;

    for (final offset in [-AbacusLayout.rodEdgeOffset, AbacusLayout.rodEdgeOffset]) {
      canvas.drawLine(
        Offset(cx + offset, AbacusLayout.rodTopY),
        Offset(cx + offset, bottomY),
        edgePaint,
      );
    }

    canvas.drawLine(
      Offset(cx, AbacusLayout.rodTopY),
      Offset(cx, bottomY),
      Paint()
        ..color = AbacusColors.rod
        ..strokeWidth = AbacusLayout.rodStrokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  void _paintRodBeads(Canvas canvas, int rodIndex, RodBeadLayout beadLayout) {
    final cx = rodCenterX(rodIndex);

    _paintHexBead(canvas, cx, beadLayout.heavenY);

    for (var beadIndex = 0; beadIndex < beadLayout.earthYs.length; beadIndex++) {
      _paintHexBead(
        canvas,
        cx,
        beadLayout.earthYs[beadIndex],
        marked: isMarkedEarthBead(rodIndex, beadIndex, totalRods),
      );
    }
  }

  void _paintHexBead(Canvas canvas, double cx, double cy, {bool marked = false}) {
    final halfHeight = AbacusLayout.beadHeight / 2;
    final slant = AbacusLayout.beadHalfWidth * AbacusLayout.beadSlantRatio;
    final left = cx - AbacusLayout.beadHalfWidth;
    final right = cx + AbacusLayout.beadHalfWidth;

    final path = Path()
      ..moveTo(left, cy)
      ..lineTo(left + slant, cy - halfHeight)
      ..lineTo(right - slant, cy - halfHeight)
      ..lineTo(right, cy)
      ..lineTo(right - slant, cy + halfHeight)
      ..lineTo(left + slant, cy + halfHeight)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..color = marked ? AbacusColors.beadMarkerFill : AbacusColors.beadFill
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = AbacusColors.beadStroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = AbacusLayout.beadStrokeWidth,
    );
  }

  @override
  bool shouldRepaint(covariant AbacusPainter oldDelegate) {
    return oldDelegate.rodLayouts != rodLayouts ||
        oldDelegate.totalRods != totalRods;
  }
}
