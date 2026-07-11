/// Web v2: `platform/src/trainers/math/fruit-count-tap/fruit-icon-size.ts`

const fruitIconSizeRatio = 0.08;
const fruitIconSizeMaxPx = 64.0;

double getFruitIconSizePx(double viewportHeight) {
  if (!viewportHeight.isFinite || viewportHeight <= 0) {
    return 56;
  }

  return (viewportHeight * fruitIconSizeRatio).clamp(0, fruitIconSizeMaxPx).roundToDouble();
}
