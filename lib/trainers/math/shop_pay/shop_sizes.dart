/// Web v2: `platform/src/trainers/math/shop-pay/shop-sizes.ts`

double shopItemIconSize(double viewportHeight) {
  return _minSvh(viewportHeight, 0.14, 96);
}

double shopTrayCoinSize(double viewportHeight) {
  return _minSvh(viewportHeight, 0.10, 64);
}

double shopRegisterCoinSize(double viewportHeight) {
  return _minSvh(viewportHeight, 0.09, 58);
}

double shopDragCoinSize(double viewportHeight) {
  return _minSvh(viewportHeight, 0.11, 72);
}

double shopPriceFontSize(double viewportHeight) {
  return _minSvh(viewportHeight, 0.08, 48);
}

double shopPaidAmountFontSize(double viewportHeight) {
  return _minSvh(viewportHeight, 0.06, 36);
}

double _minSvh(double viewportHeight, double fraction, double maxPx) {
  if (viewportHeight <= 0) {
    return maxPx;
  }

  final svhValue = viewportHeight * fraction;
  return svhValue < maxPx ? svhValue : maxPx;
}
