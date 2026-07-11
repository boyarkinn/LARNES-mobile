import 'package:larnes_mobile/trainers/math/fruit_count_tap/fruit_reveal.dart';

/// Web v2: `platform/src/trainers/math/shop-pay/shop-reveal.ts`

const shopShowcaseRevealDelayMs = 0;
const shopRegisterRevealDelayMs = 350;
const kShopPopDurationMs = kFruitPopDurationMs;

int getShopCoinRevealStartMs() {
  return shopRegisterRevealDelayMs + kFruitPopDurationMs;
}

int getShopCoinRevealDelayMs(int index, int coinCount) {
  return getShopCoinRevealStartMs() + getFruitRevealDelayMs(index, coinCount);
}

int getShopPayRevealStartMs(int coinCount) {
  return getShopCoinRevealStartMs() + getFruitRevealTotalMs(coinCount);
}

/// Drag/tap and pay CTA unlock after the full reveal chain.
int getShopInteractionReadyMs(int coinCount) {
  return getShopPayRevealStartMs(coinCount) + getAnswerRevealTotalMs(1);
}
