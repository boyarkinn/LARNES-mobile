import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/math/shop_pay/shop_pay_model.dart';

void main() {
  group('validatePayment', () {
    test('accepts exact payment', () {
      final result = validatePayment(3, 3);

      expect(result.ok, isTrue);
      expect(result.paid, 3);
    });

    test('rejects underpayment with message', () {
      final result = validatePayment(5, 2);

      expect(result.ok, isFalse);
      expect(result.message, contains('2 ₽'));
      expect(result.message, contains('5 ₽'));
    });

    test('rejects overpayment with message', () {
      final result = validatePayment(3, 4);

      expect(result.ok, isFalse);
      expect(result.message, contains('4 ₽'));
      expect(result.message, contains('3 ₽'));
    });
  });

  group('coin helpers', () {
    test('builds coins in tray with denominations', () {
      final coins = buildCoinTrayForParams(item: 'candy', price: 13, coinCount: 8);

      expect(coins.length, 8);
      expect(sumCoinsInRegister(coins), 0);
      expect(coins.every((coin) => shopCoinDenominations.contains(coin.value)), isTrue);
    });

    test('moves coin to register and sums values', () {
      final coins = moveCoinToZone(
        buildCoinTrayForParams(item: 'candy', price: 7, coinCount: 6),
        'coin-1',
        coinZoneRegister,
      );

      expect(sumCoinsInRegister(coins), greaterThanOrEqualTo(1));
    });

    test('resets coins to tray', () {
      final coins = resetCoinsToTray(
        moveCoinToZone(
          buildCoinTrayForParams(item: 'candy', price: 5, coinCount: 6),
          'coin-1',
          coinZoneRegister,
        ),
      );

      expect(sumCoinsInRegister(coins), 0);
    });
  });

  group('isShopCoinCountValid', () {
    test('requires enough slots for the minimum decomposition', () {
      expect(isShopCoinCountValid(6, 13), isTrue);
      expect(isShopCoinCountValid(2, 13), isFalse);
      expect(minCoinsForPrice(50), 5);
      expect(isShopCoinCountValid(5, 50), isTrue);
    });
  });

  group('buildCoinTray', () {
    test('always includes a subset that pays the price', () {
      final coins = buildCoinTrayForParams(item: 'banana', price: 37, coinCount: 10);

      expect(coins.length, 10);
      expect(
        trayCanPayPrice(coins.map((coin) => coin.value).toList(), 37),
        isTrue,
      );
    });

    test('is deterministic for the same params', () {
      final first = buildCoinTrayForParams(item: 'car', price: 18, coinCount: 8)
          .map((coin) => coin.value)
          .toList();
      final second = buildCoinTrayForParams(item: 'car', price: 18, coinCount: 8)
          .map((coin) => coin.value)
          .toList();

      expect(first, second);
    });
  });
}
