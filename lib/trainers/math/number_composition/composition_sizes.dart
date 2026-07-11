import 'package:flutter/material.dart';

/// Web v2: `platform/src/trainers/math/number-composition/composition-sizes.ts`

const compositionWholeColor = Color(0xFF22C55E);
const compositionDotColor = Color(0xFF3B6FD4);

double compositionDotSlotSize(double viewportHeight) {
  return _minSvh(viewportHeight, 0.20, 112);
}

double compositionDotChoiceSize(double viewportHeight) {
  return _minSvh(viewportHeight, 0.14, 80);
}

double compositionDigitFontSize(double viewportHeight) {
  return _minSvh(viewportHeight, 0.16, 80);
}

double compositionOperatorFontSize(double viewportHeight) {
  return _minSvh(viewportHeight, 0.10, 56);
}

double compositionChoiceButtonHeight(double viewportHeight) {
  return _minSvh(viewportHeight, 0.075, 72);
}

double _minSvh(double viewportHeight, double fraction, double maxPx) {
  final svhValue = viewportHeight * fraction;
  return svhValue < maxPx ? svhValue : maxPx;
}
