/// Web: `platform/src/trainers/reading/schulte-table/schulte-table-sizes.ts`

import 'dart:math' as math;

const kSchulteWrongShakeMs = 450;
const kSchulteRoundSettleMs = 700;

double schulteGridBoxSize(double viewportHeight, double viewportWidth) {
  if (!viewportHeight.isFinite ||
      viewportHeight <= 0 ||
      !viewportWidth.isFinite ||
      viewportWidth <= 0) {
    return 280;
  }

  return math.min(viewportHeight * 0.86, viewportWidth * 0.94);
}

double schulteGridGap(int gridSize) => gridSize >= 8 ? 1 : 2;

double schulteCellFontSize(double boxSize, int gridSize) {
  final size = gridSize.clamp(3, 10);
  final gap = schulteGridGap(size);
  final cell = (boxSize - gap * (size - 1)) / size;
  return (cell * 0.42).clamp(10.0, 44.0);
}
