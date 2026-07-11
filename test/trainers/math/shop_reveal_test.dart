import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/math/shop_pay/shop_reveal.dart';
import 'package:larnes_mobile/trainers/shared/trainer_constants.dart';

void main() {
  group('shop reveal timeline', () {
    test('reveals pay button after coins and interaction after pay', () {
      const coinCount = 6;

      expect(getShopCoinRevealStartMs(), greaterThan(0));
      expect(
        getShopPayRevealStartMs(coinCount),
        greaterThan(getShopCoinRevealStartMs()),
      );
      expect(
        getShopInteractionReadyMs(coinCount),
        greaterThan(getShopPayRevealStartMs(coinCount)),
      );
    });

    test('keeps interaction ready within a reasonable upper bound', () {
      for (var coinCount = 1; coinCount <= maxShopCoins; coinCount++) {
        expect(getShopInteractionReadyMs(coinCount), lessThanOrEqualTo(5000));
      }
    });
  });
}
