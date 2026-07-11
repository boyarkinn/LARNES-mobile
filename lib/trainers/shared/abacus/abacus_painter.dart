import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_geometry.dart';

abstract final class AbacusColors {
  static const bar = Color(0xFF6B5344);
  static const beadFill = Color(0xFFFFFCF8);
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
      _paintRod(canvas, rodIndex, rodLayouts[rodIndex], rodLineBottomY);
    }
  }

  void _paintRod(
    Canvas canvas,
    int rodIndex,
    RodBeadLayout beadLayout,
    double bottomY,
  ) {
    final cx = rodCenterX(rodIndex);

    canvas.drawLine(
      Offset(cx, AbacusLayout.rodTopY),
      Offset(cx, bottomY),
      Paint()
        ..color = AbacusColors.rod
        ..strokeWidth = AbacusLayout.rodStrokeWidth
        ..strokeCap = StrokeCap.round,
    );

    _paintHexBead(canvas, cx, beadLayout.heavenY);

    for (final earthY in beadLayout.earthYs) {
      _paintHexBead(canvas, cx, earthY);
    }
  }

  void _paintHexBead(Canvas canvas, double cx, double cy) {
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
        ..color = AbacusColors.beadFill
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
