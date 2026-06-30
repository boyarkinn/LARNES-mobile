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
    test('creates coins in tray', () {
      final coins = createCoins(4);

      expect(coins.length, 4);
      expect(countCoinsInRegister(coins), 0);
    });

    test('moves coin to register', () {
      final coins = moveCoinToZone(createCoins(3), 'coin-1', coinZoneRegister);

      expect(countCoinsInRegister(coins), 1);
    });

    test('resets coins to tray', () {
      final coins = resetCoinsToTray(
        moveCoinToZone(createCoins(2), 'coin-1', coinZoneRegister),
      );

      expect(countCoinsInRegister(coins), 0);
    });
  });

  group('isShopCoinCountValid', () {
    test('requires at least price coins', () {
      expect(isShopCoinCountValid(5, 3), isTrue);
      expect(isShopCoinCountValid(2, 3), isFalse);
    });
  });
}
