import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_geometry.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_material.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_model.dart';

export 'abacus_material.dart' show AbacusColors;

class AbacusPainter extends CustomPainter {
  AbacusPainter({
    required this.rodLayouts,
    required this.rods,
    required this.totalRods,
    this.activeBeadColor,
    this.loweringBeadColor,
    this.movingBeadHighlights,
    this.raisingBeadColor,
  });

  final List<RodBeadLayout> rodLayouts;
  final List<RodState> rods;
  final int totalRods;
  final Color? activeBeadColor;
  final Color? loweringBeadColor;
  final List<RodMovingBeadHighlight>? movingBeadHighlights;
  final Color? raisingBeadColor;
  final _material = AbacusMaterialPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final viewBox = abacusViewBox(totalRods);

    _material.paintRails(canvas, viewBox);

    for (var rodIndex = 0; rodIndex < rodLayouts.length; rodIndex++) {
      _material.paintRod(canvas, rodIndex, viewBox);
    }

    _material.paintBars(canvas, viewBox);

    for (var rodIndex = 0; rodIndex < rodLayouts.length; rodIndex++) {
      _paintRodBeads(
        canvas,
        rodIndex,
        rodLayouts[rodIndex],
        rods[rodIndex],
        movingBeadHighlights == null ? null : movingBeadHighlights![rodIndex],
      );
    }
  }

  void _paintRodBeads(
    Canvas canvas,
    int rodIndex,
    RodBeadLayout beadLayout,
    RodState rodState,
    RodMovingBeadHighlight? movingHighlight,
  ) {
    final cx = rodCenterX(rodIndex);

    _material.paintBead(
      canvas,
      cx,
      beadLayout.heavenY,
      fill: _beadFill(
        direction: movingHighlight?.heaven,
        active: rodState.heavenUp,
      ),
    );

    for (
      var beadIndex = 0;
      beadIndex < beadLayout.earthYs.length;
      beadIndex++
    ) {
      final isActive = beadIndex < rodState.earthCount;
      _material.paintBead(
        canvas,
        cx,
        beadLayout.earthYs[beadIndex],
        fill: _beadFill(
          direction: earthBeadMoveDirection(movingHighlight, beadIndex),
          active: isActive,
        ),
        marked: isMarkedEarthBead(rodIndex, beadIndex, totalRods),
      );
    }
  }

  Color? _beadFill({
    required BeadMoveDirection? direction,
    required bool active,
  }) {
    if (direction == BeadMoveDirection.raise && raisingBeadColor != null) {
      return raisingBeadColor;
    }

    if (direction == BeadMoveDirection.lower && loweringBeadColor != null) {
      return loweringBeadColor;
    }

    if (active && activeBeadColor != null) {
      return activeBeadColor;
    }

    return null;
  }

  @override
  bool shouldRepaint(covariant AbacusPainter oldDelegate) {
    return oldDelegate.rodLayouts != rodLayouts ||
        oldDelegate.rods != rods ||
        oldDelegate.totalRods != totalRods ||
        oldDelegate.activeBeadColor != activeBeadColor ||
        oldDelegate.loweringBeadColor != loweringBeadColor ||
        oldDelegate.movingBeadHighlights != movingBeadHighlights ||
        oldDelegate.raisingBeadColor != raisingBeadColor;
  }
}
