import 'dart:math' as math;

/// Web: `platform/src/trainers/reading/letter-case-color/case-color-pad-size.ts`

const caseColorPadSizeSvhFraction = 0.40;
const caseColorPadMaxWidthVwFraction = 0.42;
const caseColorGridMaxWidthPx = 720.0;
const caseColorGridMaxWidthVwFraction = 0.92;

double caseColorPadSize(double viewportHeight, double viewportWidth) {
  final svh = viewportHeight * caseColorPadSizeSvhFraction;
  final vw = viewportWidth * caseColorPadMaxWidthVwFraction;
  return math.min(svh, vw);
}

double caseColorGridMaxWidth(double viewportWidth) {
  return math.min(
    viewportWidth * caseColorGridMaxWidthVwFraction,
    caseColorGridMaxWidthPx,
  );
}
