import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Web v2: `platform/src/trainers/math/number-row-show/number-row-sizes.ts`

const numberRowWidthVwFraction = 0.96;
const numberRowMaxWidthPx = 1100.0;
const numberRowMaxHeightSvhFraction = 0.28;
const numberRowStudyPulseMs = 2400;

const numberRowInactiveColor = Color(0xFF94A3B8);
const numberRowBaselineColor = Color(0xFFCBD5E1);

/// Web pop ease: cubic-bezier(0.34, 1.2, 0.64, 1).
const numberRowPopCurve = Cubic(0.34, 1.2, 0.64, 1);

double numberRowSceneWidth(double viewportWidth) {
  return math.min(viewportWidth * numberRowWidthVwFraction, numberRowMaxWidthPx);
}

double numberRowSceneMaxHeight(double viewportHeight) {
  return viewportHeight * numberRowMaxHeightSvhFraction;
}
