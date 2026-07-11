import 'dart:math';

/// Web: `platform/src/trainers/reading/letter-orientation-pick/orientation-board.tsx`

double getOrientationPickTileSizePx(double viewportHeight, double viewportWidth) {
  if (!viewportHeight.isFinite || viewportHeight <= 0) {
    return 72;
  }

  final fromHeight = viewportHeight * 0.18;
  final fromWidth =
      viewportWidth.isFinite && viewportWidth > 0 ? viewportWidth * 0.22 : fromHeight;
  final raw = min(fromHeight, fromWidth);
  final maxTile = viewportWidth.isFinite && viewportWidth > 0
      ? min(viewportHeight * 0.22, viewportWidth * 0.28)
      : viewportHeight * 0.22;

  return raw.clamp(48, maxTile).roundToDouble();
}

double getOrientationPickLetterFontSizePx(
  double viewportHeight,
  double viewportWidth,
) {
  final fromHeight = viewportHeight * 0.14;
  final fromWidth =
      viewportWidth.isFinite && viewportWidth > 0 ? viewportWidth * 0.18 : fromHeight;

  return min(fromHeight, fromWidth).clamp(24, 120).roundToDouble();
}

int getOrientationPickGridCrossAxisCount(int optionCount, double viewportWidth) {
  if (optionCount <= 4) {
    return 2;
  }

  if (viewportWidth >= 640) {
    return 3;
  }

  return 2;
}
