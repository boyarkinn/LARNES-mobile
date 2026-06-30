import 'package:larnes_mobile/trainers/shared/trainer_constants.dart';

typedef ShopItemSlug = String;
typedef CoinZone = String;

const coinZoneTray = 'tray';
const coinZoneRegister = 'register';

const shopItemLabels = <String, String>{
  'banana': 'Банан',
  'candy': 'Конфетка',
  'car': 'Машина',
  'doll': 'Кукла',
  'ice-cream': 'Мороженое',
};

class ShopCoin {
  const ShopCoin({
    required this.id,
    required this.zone,
  });

  final String id;
  final CoinZone zone;

  ShopCoin copyWith({CoinZone? zone}) {
    return ShopCoin(id: id, zone: zone ?? this.zone);
  }
}

class PaymentValidation {
  const PaymentValidation({
    required this.ok,
    required this.paid,
    required this.price,
    this.message,
  });

  final bool ok;
  final int paid;
  final int price;
  final String? message;
}

bool isShopItemSlug(String value) => shopItemSlugs.contains(value);

String normalizeShopItemSlug(String value) {
  return isShopItemSlug(value) ? value : 'candy';
}

List<ShopCoin> createCoins(int coinCount) {
  return List.generate(
    coinCount,
    (index) => ShopCoin(
      id: 'coin-${index + 1}',
      zone: coinZoneTray,
    ),
  );
}

int countCoinsInRegister(List<ShopCoin> coins) {
  return coins.where((coin) => coin.zone == coinZoneRegister).length;
}

List<ShopCoin> moveCoinToZone(
  List<ShopCoin> coins,
  String coinId,
  CoinZone zone,
) {
  return coins
      .map((coin) => coin.id == coinId ? coin.copyWith(zone: zone) : coin)
      .toList();
}

List<ShopCoin> resetCoinsToTray(List<ShopCoin> coins) {
  return coins
      .map((coin) => coin.copyWith(zone: coinZoneTray))
      .toList();
}

PaymentValidation validatePayment(int price, int paid) {
  if (paid == price) {
    return PaymentValidation(ok: true, paid: paid, price: price);
  }

  return PaymentValidation(
    ok: false,
    paid: paid,
    price: price,
    message:
        'Ты положил $paid ₽, а нужно $price ₽. Попробуй посчитать ещё раз.',
  );
}

bool isShopCoinCountValid(int coinCount, int price) {
  return isCoinCountValid(coinCount, price);
}
