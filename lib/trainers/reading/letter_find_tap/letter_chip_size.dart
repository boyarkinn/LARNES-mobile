/// Web: `platform/src/trainers/reading/letter-find-tap/letter-chip-size.ts`

double getLetterChipSizePx(double viewportHeight) {
  if (!viewportHeight.isFinite || viewportHeight <= 0) {
    return 72;
  }

  return (viewportHeight * 0.16).clamp(0, 80).roundToDouble();
}

double getLetterChipFontSizePx(double chipSize) {
  return (chipSize * 0.72).roundToDouble();
}
