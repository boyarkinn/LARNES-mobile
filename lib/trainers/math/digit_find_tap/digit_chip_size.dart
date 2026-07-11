/// Web v2: `platform/src/trainers/math/digit-find-tap/digit-chip-size.ts`

double getDigitChipSizePx(double viewportHeight) {
  if (!viewportHeight.isFinite || viewportHeight <= 0) {
    return 72;
  }

  return (viewportHeight * 0.16).clamp(0, 80).roundToDouble();
}

double getDigitChipFontSizePx(double chipSize) {
  return (chipSize * 0.72).roundToDouble();
}
