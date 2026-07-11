import 'dart:math' as math;

/// Web v2: `platform/src/trainers/math/apple-count-show/apple-count-sizes.ts`

const appleSceneMaxHeightSvhFraction = 0.60;
const appleSceneMaxWidthVwFraction = 0.72;
const appleSceneMaxWidthPx = 640.0;
const appleBasketRevealMs = 400;
const appleSettlePulseMs = 2400;
const appleSceneBottomPaddingSvhFraction = 0.10;
const appleSceneBottomPaddingMaxPx = 56.0;

double appleSceneMaxHeight(double viewportHeight) {
  return viewportHeight * appleSceneMaxHeightSvhFraction;
}

double appleSceneWidth(double viewportWidth) {
  return math.min(viewportWidth * appleSceneMaxWidthVwFraction, appleSceneMaxWidthPx);
}

double appleSceneBottomPadding(double viewportHeight) {
  final svh = viewportHeight * appleSceneBottomPaddingSvhFraction;
  return svh < appleSceneBottomPaddingMaxPx ? svh : appleSceneBottomPaddingMaxPx;
}
