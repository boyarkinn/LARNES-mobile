/// Web: `platform/src/trainers/mental-arithmetic/example-visualization/moving-bead-highlights.ts`

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_model.dart';

const exampleVisualizationRaisingBeadColor = Color(0xFF22C55E);
const exampleVisualizationLoweringBeadColor = Color(0xFFEF4444);

List<RodMovingBeadHighlight> resolveMovingBeadHighlights(
  List<RodState> before,
  List<RodState> after,
) {
  return List<RodMovingBeadHighlight>.generate(before.length, (rodIndex) {
    final beforeRod = before[rodIndex];
    final afterRod = after[rodIndex];
    final raisingEarthIndices = <int>{};
    final loweringEarthIndices = <int>{};

    if (afterRod.earthCount > beforeRod.earthCount) {
      for (var index = beforeRod.earthCount; index < afterRod.earthCount; index++) {
        raisingEarthIndices.add(index);
      }
    } else if (afterRod.earthCount < beforeRod.earthCount) {
      for (var index = afterRod.earthCount; index < beforeRod.earthCount; index++) {
        loweringEarthIndices.add(index);
      }
    }

    return RodMovingBeadHighlight(
      heaven: beforeRod.heavenUp == afterRod.heavenUp
          ? null
          : afterRod.heavenUp
              ? BeadMoveDirection.raise
              : BeadMoveDirection.lower,
      raisingEarthIndices: raisingEarthIndices,
      loweringEarthIndices: loweringEarthIndices,
    );
  });
}

bool hasMovingBeadHighlight(RodMovingBeadHighlight highlight) {
  return !highlight.isEmpty;
}
