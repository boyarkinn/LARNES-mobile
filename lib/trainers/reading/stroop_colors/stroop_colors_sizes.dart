import 'dart:math' as math;
import 'dart:ui';

/// Web: `platform/src/trainers/reading/stroop-colors/stroop-colors-sizes.ts`

const stroopFinishDelayMs = 180;

const _boxHeightFraction = 0.72;
const _boxMaxWidthFraction = 0.92;
const _fontHeightFraction = 0.16;
const _fontWidthFraction = 0.11;
const _fontMin = 44.0;
const _fontMax = 116.0;

double stroopWordBoxSize(double viewportHeight, double viewportWidth) {
  if (!viewportHeight.isFinite ||
      viewportHeight <= 0 ||
      !viewportWidth.isFinite ||
      viewportWidth <= 0) {
    return 280;
  }

  return math.min(
    viewportHeight * _boxHeightFraction,
    viewportWidth * _boxMaxWidthFraction,
  );
}

double stroopWordFontSize(double viewportHeight, double viewportWidth) {
  if (!viewportHeight.isFinite ||
      viewportHeight <= 0 ||
      !viewportWidth.isFinite ||
      viewportWidth <= 0) {
    return 56;
  }

  final scaled = math.min(
    viewportHeight * _fontHeightFraction,
    viewportWidth * _fontWidthFraction,
  );

  return scaled.clamp(_fontMin, _fontMax);
}

Color stroopInkColor(String hex) {
  final value = int.parse(hex.substring(1), radix: 16);
  return Color(0xFF000000 | value);
}
