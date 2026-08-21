import 'dart:math' as math;
import 'dart:ui';

/// Web: `platform/src/trainers/reading/wedge-tables/wedge-tables-sizes.ts`

const kWedgeFinishDelayMs = 180;
const kWedgeCenterDotColor = Color(0xFF22C55E);
const kWedgeLineColor = Color(0xB322C55E);
const kWedgeTokenColor = Color(0xFF292524);

const kWedgeArmMinVmin = 6.0;
const kWedgeArmMaxVmin = 36.0;
const kWedgeLineThickness = 2.0;

const _boxHeightFraction = 0.88;
const _boxMaxWidthFraction = 0.96;
const _fontHeightFraction = 0.09;
const _fontWidthFraction = 0.10;
const _fontMin = 29.6;
const _fontMax = 60.0;

double getWedgeArmProgress(int rowIndex, int rowCount) {
  final last = math.max(rowCount - 1, 1);
  final progress = rowIndex / last;
  return progress.clamp(0.0, 1.0);
}

double getWedgeArmLength(int rowIndex, int rowCount, double shortSide) {
  final progress = getWedgeArmProgress(rowIndex, rowCount);
  final vmin = kWedgeArmMinVmin + progress * (kWedgeArmMaxVmin - kWedgeArmMinVmin);
  return shortSide * vmin / 100;
}

double wedgeSceneBoxSize(double viewportHeight, double viewportWidth) {
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

double wedgeTokenFontSize(double viewportHeight, double viewportWidth) {
  if (!viewportHeight.isFinite ||
      viewportHeight <= 0 ||
      !viewportWidth.isFinite ||
      viewportWidth <= 0) {
    return 36;
  }

  final scaled = math.min(
    viewportHeight * _fontHeightFraction,
    viewportWidth * _fontWidthFraction,
  );

  return scaled.clamp(_fontMin, _fontMax);
}

double wedgeDotSize(double shortSide) {
  return (shortSide * 0.024).clamp(12.0, 18.0);
}
