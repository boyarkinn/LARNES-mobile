import 'dart:math' as math;

/// Web v2: `platform/src/trainers/math/digit-trace/trace-pad-size.ts`

const tracePadSizeSvhFraction = 0.72;
const tracePadMaxWidthVwFraction = 0.85;

double tracePadSize(double viewportHeight, double viewportWidth) {
  final svh = viewportHeight * tracePadSizeSvhFraction;
  final vw = viewportWidth * tracePadMaxWidthVwFraction;
  return math.min(svh, vw);
}
