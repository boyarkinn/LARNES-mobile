import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_geometry.dart';

abstract final class AbacusColors {
  static const bar = Color(0xFFED9138);
  static const beadFill = Color(0xFFF7F8F8);
  static const beadMarkerFill = Color(0xFFEE4837);
  static const beadStroke = Color(0xFFBFC5C5);
  static const rod = Color(0xFFD6C4AE);
}

/// Shared physical surfaces; positions and movement remain owned by geometry.
class AbacusMaterialPainter {
  AbacusMaterialPainter({this.monochrome = false});

  final bool monochrome;
  final Map<Color, _BeadSurface> _highlightSurfaces = {};

  static const _frameColors = [
    Color(0xFFF4A04B),
    AbacusColors.bar,
    Color(0xFFE58A32),
    Color(0xFFC46D24),
  ];
  static const _railColors = [
    Color(0xFFF5A24E),
    Color(0xFFED923B),
    Color(0xFFE1852E),
    Color(0xFFC97529),
  ];
  static const _grayFrameColors = [
    Color(0xFF777777),
    Color(0xFF606060),
    Color(0xFF525252),
    Color(0xFF393939),
  ];
  static const _grayRailColors = [
    Color(0xFF7A7A7A),
    Color(0xFF646464),
    Color(0xFF515151),
    Color(0xFF3C3C3C),
  ];
  static final _rodPaint = Paint()
    ..shader = ui.Gradient.linear(
      const Offset(-.66, 0),
      const Offset(.66, 0),
      const [
        Color(0xFFAA9785),
        Color(0xFFE4D5C2),
        Color(0xFFD6C4AE),
        Color(0xFFB5A18A),
      ],
      const [0, .32, .64, 1],
    );
  static final _grayRodPaint = Paint()
    ..shader = ui.Gradient.linear(
      const Offset(-.66, 0),
      const Offset(.66, 0),
      const [
        Color(0xFF9D9D9D),
        Color(0xFFDEDEDE),
        Color(0xFFC4C4C4),
        Color(0xFFA6A6A6),
      ],
      const [0, .32, .64, 1],
    );

  void paintRails(Canvas canvas, AbacusViewBoxMetrics viewBox) {
    final rect = Rect.fromLTWH(
      0,
      viewBox.topBarY,
      AbacusLayout.sideInset,
      viewBox.bottomBarY + AbacusLayout.barHeight - viewBox.topBarY,
    );
    final fill = Paint()
      ..shader = ui.Gradient.linear(
        Offset(rect.left, 0),
        Offset(rect.right, 0),
        monochrome ? _grayRailColors : _railColors,
        const [0, .3, .8, 1],
      );
    final highlight = Paint()
      ..color = monochrome ? const Color(0x99C4C4C4) : const Color(0xA6FFC17B)
      ..strokeWidth = .45;

    for (final x in [0.0, viewBox.width - AbacusLayout.sideInset]) {
      canvas.save();
      canvas.translate(x, 0);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(1)),
        fill,
      );
      canvas.drawLine(
        Offset(.7, viewBox.topBarY + 2),
        Offset(.7, viewBox.bottomBarY + 2),
        highlight,
      );
      canvas.restore();
    }
  }

  void paintRod(Canvas canvas, int rodIndex, AbacusViewBoxMetrics viewBox) {
    canvas.save();
    canvas.translate(rodCenterX(rodIndex), 0);
    canvas.drawRect(
      Rect.fromLTWH(
        -.66,
        viewBox.topBarY + AbacusLayout.barHeight,
        1.32,
        viewBox.bottomBarY - viewBox.topBarY - AbacusLayout.barHeight,
      ),
      monochrome ? _grayRodPaint : _rodPaint,
    );
    canvas.restore();
  }

  void paintBars(Canvas canvas, AbacusViewBoxMetrics viewBox) {
    final rect = Rect.fromLTWH(0, 0, viewBox.width, AbacusLayout.barHeight);
    final fill = Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        const Offset(0, AbacusLayout.barHeight),
        monochrome ? _grayFrameColors : _frameColors,
        const [0, .22, .72, 1],
      );
    final highlight = Paint()
      ..color = monochrome ? const Color(0xB8C4C4C4) : const Color(0xB8FFC17C)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = .45;
    final shadow = Paint()
      ..color = monochrome ? const Color(0x85303030) : const Color(0x85B96825)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = .38;

    for (final y in [viewBox.topBarY, viewBox.beamY, viewBox.bottomBarY]) {
      canvas.save();
      canvas.translate(0, y);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(.85)),
        fill,
      );
      canvas.drawLine(
        const Offset(1.1, .65),
        Offset(viewBox.width - 1.1, .65),
        highlight,
      );
      canvas.drawLine(
        const Offset(1, AbacusLayout.barHeight - .55),
        Offset(viewBox.width - 1, AbacusLayout.barHeight - .55),
        shadow,
      );
      canvas.restore();
    }
  }

  void paintBead(
    Canvas canvas,
    double cx,
    double cy, {
    Color? fill,
    bool marked = false,
  }) {
    final surface = fill == null
        ? (marked && !monochrome ? _BeadSurface.red : _BeadSurface.ivory)
        : _highlightSurfaces.putIfAbsent(fill, () => _BeadSurface.tinted(fill));
    canvas.save();
    canvas.translate(cx, cy);
    canvas.drawPath(_upperFacet, surface.upper);
    canvas.drawPath(_lowerFacet, surface.lower);
    canvas.drawPath(_ridge, surface.ridge);
    canvas.drawPath(_upperGlint, surface.highlight);
    canvas.drawPath(_lowerEdge, surface.shadow);
    canvas.restore();
  }

  // Softened six-corner silhouette, exactly 26.4 × 17 geometry units.
  static final _upperFacet = Path()
    ..moveTo(-13.2, 0)
    ..quadraticBezierTo(-13.2, -.55, -12.82, -1.14)
    ..lineTo(-8.02, -7.88)
    ..quadraticBezierTo(-7.58, -8.5, -6.82, -8.5)
    ..lineTo(6.82, -8.5)
    ..quadraticBezierTo(7.58, -8.5, 8.02, -7.88)
    ..lineTo(12.82, -1.14)
    ..quadraticBezierTo(13.2, -.55, 13.2, 0)
    ..close();
  static final _lowerFacet = Path()
    ..moveTo(-13.2, 0)
    ..lineTo(13.2, 0)
    ..quadraticBezierTo(13.2, .55, 12.82, 1.14)
    ..lineTo(8.02, 7.88)
    ..quadraticBezierTo(7.58, 8.5, 6.82, 8.5)
    ..lineTo(-6.82, 8.5)
    ..quadraticBezierTo(-7.58, 8.5, -8.02, 7.88)
    ..lineTo(-12.82, 1.14)
    ..quadraticBezierTo(-13.2, .55, -13.2, 0)
    ..close();
  static final _ridge = Path()
    ..moveTo(-13.18, -.16)
    ..quadraticBezierTo(-6.6, -.62, 0, -.49)
    ..quadraticBezierTo(6.6, -.47, 13.18, -.16)
    ..lineTo(13.18, .25)
    ..quadraticBezierTo(6.6, .63, 0, .58)
    ..quadraticBezierTo(-6.6, .58, -13.18, .25)
    ..close();
  static final _upperGlint = Path()
    ..moveTo(-11.47, -2.3)
    ..lineTo(-7.46, -7.86)
    ..quadraticBezierTo(-7.23, -8.13, -6.64, -8.13)
    ..lineTo(5.6, -8.13);
  static final _lowerEdge = Path()
    ..moveTo(-6.75, 8.1)
    ..lineTo(6.75, 8.1)
    ..quadraticBezierTo(7.3, 8.1, 7.58, 7.7)
    ..lineTo(10.62, 3.45);
}

class _BeadSurface {
  _BeadSurface({
    required List<Color> upperColors,
    required List<Color> lowerColors,
    required List<Color> ridgeColors,
    required Color highlightColor,
    required Color shadowColor,
    bool red = false,
  }) : upper = Paint()
         ..shader = _faceGradient(
           upperColors,
           red ? .1 : .15,
           red ? .8 : .75,
           -8.5,
           0,
           red ? .4 : .48,
         ),
       lower = Paint()
         ..shader = _faceGradient(
           lowerColors,
           red ? .15 : .2,
           red ? .7 : .68,
           0,
           8.5,
           red ? .6 : .55,
         ),
       ridge = Paint()
         ..shader = ui.Gradient.linear(
           const Offset(0, -.62),
           const Offset(0, .63),
           ridgeColors,
           [0, red ? .55 : .52, 1],
         ),
       highlight = Paint()
         ..color = highlightColor
         ..style = PaintingStyle.stroke
         ..strokeCap = StrokeCap.round
         ..strokeWidth = .34,
       shadow = Paint()
         ..color = shadowColor
         ..style = PaintingStyle.stroke
         ..strokeCap = StrokeCap.round
         ..strokeWidth = .3;

  factory _BeadSurface.tinted(Color color) {
    Color tint(Color target, double amount) =>
        Color.lerp(color, target.withValues(alpha: color.a), amount)!;
    return _BeadSurface(
      upperColors: [tint(Colors.white, .25), color, tint(Colors.black, .09)],
      lowerColors: [
        tint(Colors.black, .06),
        tint(Colors.black, .16),
        tint(Colors.black, .28),
      ],
      ridgeColors: [
        tint(Colors.white, .4),
        tint(Colors.white, .1),
        tint(Colors.black, .2),
      ],
      highlightColor: tint(Colors.white, .65).withValues(alpha: color.a * .7),
      shadowColor: tint(Colors.black, .4).withValues(alpha: color.a * .38),
    );
  }

  final Paint upper;
  final Paint lower;
  final Paint ridge;
  final Paint highlight;
  final Paint shadow;

  static ui.Shader _faceGradient(
    List<Color> colors,
    double startX,
    double endX,
    double top,
    double bottom,
    double middleStop,
  ) => ui.Gradient.linear(
    Offset(-13.2 + 26.4 * startX, top),
    Offset(-13.2 + 26.4 * endX, bottom),
    colors,
    [0, middleStop, 1],
  );

  static final ivory = _BeadSurface(
    upperColors: const [
      Color(0xFFFFFFFF),
      Color(0xFFF7F8F8),
      Color(0xFFE3E5E5),
    ],
    lowerColors: const [
      Color(0xFFE0E3E3),
      Color(0xFFD5D8D8),
      Color(0xFFBCC1C2),
    ],
    ridgeColors: const [
      Color(0xFFFFFFFF),
      Color(0xFFF1F3F3),
      Color(0xFFBFC5C5),
    ],
    highlightColor: const Color(0xDBFFFFFF),
    shadowColor: const Color(0x61BFB5A4),
  );
  static final red = _BeadSurface(
    upperColors: const [
      Color(0xFFFA6752),
      Color(0xFFEE4837),
      Color(0xFFD82A26),
    ],
    lowerColors: const [
      Color(0xFFDF302B),
      Color(0xFFC82524),
      Color(0xFFA91C20),
    ],
    ridgeColors: const [
      Color(0xFFFF8B77),
      Color(0xFFF25845),
      Color(0xFFB41E22),
    ],
    highlightColor: const Color(0x91FFB2A0),
    shadowColor: const Color(0x61AF4434),
    red: true,
  );
}
