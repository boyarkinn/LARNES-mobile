import 'package:larnes_mobile/trainers/shared/seeded_rng.dart';
import 'package:larnes_mobile/trainers/shared/trainer_constants.dart';

typedef ShopItemSlug = String;
typedef CoinZone = String;

const coinZoneTray = 'tray';
const coinZoneRegister = 'register';

const shopCoinDenominations = [1, 2, 5, 10];

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
    required this.value,
    required this.zone,
  });

  final String id;
  final int value;
  final CoinZone zone;

  ShopCoin copyWith({CoinZone? zone}) {
    return ShopCoin(id: id, value: value, zone: zone ?? this.zone);
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

int minCoinsForPrice(int price) {
  var remaining = price.clamp(0, 1 << 30);
  var count = 0;

  for (final denomination in [10, 5, 2, 1]) {
    while (remaining >= denomination) {
      remaining -= denomination;
      count += 1;
    }
  }

  return count;
}

bool isShopCoinCountValid(int coinCount, int price) {
  return isCoinCountValid(coinCount, price);
}

int buildShopCoinTraySeed(String item, int price, int coinCount) {
  return hashParamsSeed([item, price, coinCount, 'shop-pay']);
}

List<int> buildCoinValues(int price, int coinCount, int seed) {
  final rng = createSeededRng(seed);
  final solution = _buildRandomSolution(price, coinCount, rng);
  final values = List<int>.from(solution);

  while (values.length < coinCount) {
    final pick = shopCoinDenominations[(rng() * shopCoinDenominations.length).floor()];
    values.add(pick);
  }

  return _shuffleItems(values, rng).take(coinCount).toList(growable: false);
}

List<ShopCoin> buildCoinTray(int price, int coinCount, int seed) {
  return buildCoinValues(price, coinCount, seed)
      .asMap()
      .entries
      .map(
        (entry) => ShopCoin(
          id: 'coin-${entry.key + 1}',
          value: entry.value,
          zone: coinZoneTray,
        ),
      )
      .toList(growable: false);
}

List<ShopCoin> buildCoinTrayForParams({
  required String item,
  required int price,
  required int coinCount,
}) {
  return buildCoinTray(
    price,
    coinCount,
    buildShopCoinTraySeed(item, price, coinCount),
  );
}

int sumCoinsInRegister(List<ShopCoin> coins) {
  return coins
      .where((coin) => coin.zone == coinZoneRegister)
      .fold<int>(0, (sum, coin) => sum + coin.value);
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

bool trayCanPayPrice(List<int> values, int price) {
  return _subsetSumsToTarget(values, price);
}

List<int> _buildRandomSolution(int price, int maxCoins, double Function() rng) {
  for (var attempt = 0; attempt < 64; attempt++) {
    final coins = <int>[];
    var remaining = price;

    while (remaining > 0) {
      final options =
          shopCoinDenominations.where((denomination) => denomination <= remaining).toList();
      final pick = options[(rng() * options.length).floor()];
      coins.add(pick);
      remaining -= pick;
    }

    if (coins.length <= maxCoins) {
      return coins;
    }
  }

  return _decomposePriceGreedy(price);
}

List<int> _decomposePriceGreedy(int price) {
  final coins = <int>[];
  var remaining = price;

  for (final denomination in [10, 5, 2, 1]) {
    while (remaining >= denomination) {
      coins.add(denomination);
      remaining -= denomination;
    }
  }

  return coins;
}

List<int> _shuffleItems(List<int> items, double Function() rng) {
  final next = List<int>.from(items);

  for (var index = next.length - 1; index > 0; index--) {
    final swapIndex = (rng() * (index + 1)).floor();
    final temp = next[index];
    next[index] = next[swapIndex];
    next[swapIndex] = temp;
  }

  return next;
}

bool _subsetSumsToTarget(List<int> values, int target) {
  if (target == 0) {
    return true;
  }
  if (target < 0 || values.isEmpty) {
    return false;
  }

  final rest = values.sublist(1);
  final first = values.first;

  return _subsetSumsToTarget(rest, target - first) ||
      _subsetSumsToTarget(rest, target);
}

@Deprecated('Use buildCoinTrayForParams')
List<ShopCoin> createCoins(int coinCount) {
  return buildCoinTray(coinCount, coinCount, buildShopCoinTraySeed('candy', coinCount, coinCount));
}

@Deprecated('Use sumCoinsInRegister')
int countCoinsInRegister(List<ShopCoin> coins) => sumCoinsInRegister(coins);
