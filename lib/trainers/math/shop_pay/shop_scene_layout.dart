import 'dart:math' as math;

import 'package:larnes_mobile/trainers/math/shop_pay/shop_sizes.dart';

/// Web v2: `shop-scene.tsx` — flex-[1.1] / flex-[1.35] / flex-1.

class ShopSceneLayout {
  const ShopSceneLayout({
    required this.itemSize,
    required this.trayCoinSize,
    required this.registerCoinSize,
    required this.dragCoinSize,
    required this.priceFontSize,
    required this.paidFontSize,
    required this.showcaseHeight,
  });

  final double itemSize;
  final double trayCoinSize;
  final double registerCoinSize;
  final double dragCoinSize;
  final double priceFontSize;
  final double paidFontSize;
  final double showcaseHeight;
}

const showcaseFlex = 110.0;
const registerFlex = 135.0;
const trayFlex = 100.0;
const _totalFlex = showcaseFlex + registerFlex + trayFlex;

const _showcaseVerticalPadding = 16.0;
const _priceGap = 12.0;
const _priceLineHeight = 1.25;
const _itemAbsoluteMinPx = 28.0;
const _itemMaxPx = 96.0;

ShopSceneLayout computeShopSceneLayout({
  required double viewportWidth,
  required double viewportHeight,
  double payFooterHeight = 68,
}) {
  final expandedHeight = math.max(0, viewportHeight - payFooterHeight);
  final showcaseHeight =
      expandedHeight * (showcaseFlex / _totalFlex) - _showcaseVerticalPadding;

  var priceFontSize = shopPriceFontSize(viewportHeight);
  var maxItemFromZone =
      showcaseHeight - _priceGap - priceFontSize * _priceLineHeight;

  if (maxItemFromZone < _itemAbsoluteMinPx) {
    priceFontSize = math.max(
      16,
      (showcaseHeight - _priceGap - _itemAbsoluteMinPx) / _priceLineHeight,
    );
    maxItemFromZone =
        showcaseHeight - _priceGap - priceFontSize * _priceLineHeight;
  }

  final itemSize = math
      .min(shopItemIconSize(viewportHeight), maxItemFromZone)
      .clamp(_itemAbsoluteMinPx, _itemMaxPx);

  return ShopSceneLayout(
    itemSize: itemSize,
    trayCoinSize: shopTrayCoinSize(viewportHeight),
    registerCoinSize: shopRegisterCoinSize(viewportHeight),
    dragCoinSize: shopDragCoinSize(viewportHeight),
    priceFontSize: priceFontSize,
    paidFontSize: shopPaidAmountFontSize(viewportHeight),
    showcaseHeight: showcaseHeight,
  );
}
