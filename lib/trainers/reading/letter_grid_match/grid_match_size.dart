import 'dart:math' as math;

/// Web: `platform/src/trainers/reading/letter-grid-match/grid-match-size.ts`

const gridPanelSizeSvhFraction = 0.28;
const gridPanelMaxWidthVwFraction = 0.38;

double gridPanelSize(double viewportHeight, double viewportWidth) {
  final svh = viewportHeight * gridPanelSizeSvhFraction;
  final vw = viewportWidth * gridPanelMaxWidthVwFraction;
  return math.min(svh, vw);
}

double getGridCellFontSize(int gridSize) {
  if (gridSize == 2) {
    return 40;
  }

  return 30;
}
