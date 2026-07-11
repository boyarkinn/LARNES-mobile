import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/math/shop_pay/shop_scene_layout.dart';

void main() {
  group('computeShopSceneLayout', () {
    test('showcase gets web flex share of expanded height', () {
      const height = 600.0;
      final layout = computeShopSceneLayout(
        viewportWidth: 360,
        viewportHeight: height,
      );

      final expanded = height - 68;
      final flexShare = expanded * (showcaseFlex / _totalFlex);
      expect(layout.showcaseHeight, closeTo(flexShare - 16, 0.5));
      expect(flexShare / expanded, closeTo(110 / _totalFlex, 0.001));
    });

    test('portrait item icon is readable, not crushed by tiny showcase', () {
      final layout = computeShopSceneLayout(
        viewportWidth: 360,
        viewportHeight: 640,
      );

      expect(layout.itemSize, greaterThanOrEqualTo(48));
      expect(layout.itemSize, lessThanOrEqualTo(96));
      expect(
        layout.itemSize + _priceGap + layout.priceFontSize * _priceLineHeight,
        lessThanOrEqualTo(layout.showcaseHeight + 1),
      );
    });

    test('landscape item icon stays visible', () {
      final layout = computeShopSceneLayout(
        viewportWidth: 640,
        viewportHeight: 360,
      );

      expect(layout.itemSize, greaterThanOrEqualTo(28));
      expect(layout.showcaseHeight, greaterThan(70));
      expect(
        layout.itemSize + _priceGap + layout.priceFontSize * _priceLineHeight,
        lessThanOrEqualTo(layout.showcaseHeight + 1),
      );
    });
  });
}

const _totalFlex = showcaseFlex + registerFlex + trayFlex;
const _priceGap = 12.0;
const _priceLineHeight = 1.25;
