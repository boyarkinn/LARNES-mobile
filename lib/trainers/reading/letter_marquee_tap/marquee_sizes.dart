import 'dart:math';

/// Web: `platform/src/trainers/reading/letter-marquee-tap/marquee-sizes.ts`

const marqueeLaneHeightSvh = 36;
const marqueeLaneMaxHeightPx = 270;

const marqueeChipSizeSvh = 0.24;
const marqueeChipMaxSizePx = 152;

const marqueeLetterColor = 0xFF1A1D2E;
const marqueeRailColor = 0xFFCBD5E1;
const marqueeProgressDoneColor = 0xFF16A34A;

double getMarqueeChipSizePx(double viewportHeight) {
  if (!viewportHeight.isFinite || viewportHeight <= 0) {
    return 144;
  }

  return min(viewportHeight * marqueeChipSizeSvh, marqueeChipMaxSizePx)
      .roundToDouble();
}

double getMarqueeChipFontSizePx(double chipSize) {
  return (chipSize * 0.72).roundToDouble();
}

double getMarqueeLaneHeightPx(double viewportHeight) {
  if (!viewportHeight.isFinite || viewportHeight <= 0) {
    return 240;
  }

  return min(
    viewportHeight * (marqueeLaneHeightSvh / 100),
    marqueeLaneMaxHeightPx.toDouble(),
  ).roundToDouble();
}
