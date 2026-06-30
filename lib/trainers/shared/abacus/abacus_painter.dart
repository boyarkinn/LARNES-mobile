import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_geometry.dart';

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
    final frameY = AbacusLayout.topPadding - 4;

    final frameRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(4, frameY, viewBox.width - 8, viewBox.height - frameY - 8),
      const Radius.circular(AbacusLayout.frameRadius),
    );
    canvas.drawRRect(
      frameRect,
      Paint()
        ..color = const Color(0xFFF3D2B6)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      frameRect,
      Paint()
        ..color = const Color(0xFFE0B894)
        ..style = PaintingStyle.stroke
        ..strokeWidth = AbacusLayout.frameStroke,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          14,
          AbacusLayout.beamY,
          viewBox.width - 28,
          AbacusLayout.beamHeight,
        ),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFFE8C4A8),
    );

    for (var rodIndex = 0; rodIndex < rodLayouts.length; rodIndex++) {
      _paintRod(canvas, rodIndex, rodLayouts[rodIndex]);
    }
  }

  void _paintRod(Canvas canvas, int rodIndex, RodBeadLayout beadLayout) {
    final cx = rodCenterX(rodIndex);
    final showUnitMarker = isUnitMarkerRod(rodIndex, totalRods);
    final bottomY =
        AbacusLayout.earthInactiveBottomY + AbacusLayout.beadHeight / 2;

    canvas.drawLine(
      Offset(cx, AbacusLayout.rodTopY),
      Offset(cx, bottomY),
      Paint()
        ..color = const Color(0xFFE8C4A8)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );

    if (showUnitMarker) {
      canvas.drawCircle(
        Offset(cx, AbacusLayout.beamY + AbacusLayout.beamHeight / 2),
        AbacusLayout.unitDotRadius,
        Paint()..color = const Color(0xFF3D3D3D),
      );
    }

    _paintBead(canvas, cx, beadLayout.heavenY, highlight: false);

    for (var beadIndex = 0; beadIndex < beadLayout.earthYs.length; beadIndex++) {
      _paintBead(
        canvas,
        cx,
        beadLayout.earthYs[beadIndex],
        highlight: showUnitMarker && beadIndex == 0,
      );
    }
  }

  void _paintBead(
    Canvas canvas,
    double cx,
    double cy, {
    required bool highlight,
  }) {
    final top = cy - AbacusLayout.beadHeight / 2;
    final bottom = cy + AbacusLayout.beadHeight / 2;
    final halfWidth = AbacusLayout.beadHalfWidth;

    final path = Path()
      ..moveTo(cx, top)
      ..lineTo(cx + halfWidth, cy)
      ..lineTo(cx, bottom)
      ..lineTo(cx - halfWidth, cy)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..color = highlight ? const Color(0xFFE53935) : const Color(0xFFFAFAFA)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFD8D0C8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant AbacusPainter oldDelegate) {
    return oldDelegate.rodLayouts != rodLayouts ||
        oldDelegate.totalRods != totalRods;
  }
}
