import 'dart:ui';

import 'package:larnes_mobile/trainers/math/fruit_count_tap/fruit_reveal.dart';

/// Web: `platform/src/trainers/reading/letter-grid-match/grid-match-reveal.ts`

const gridReferenceRevealBudgetMs = 2000;

int getReferenceRevealStaggerMs(int filledCount) {
  if (filledCount <= 1) {
    return 0;
  }

  return ((gridReferenceRevealBudgetMs - fruitPopDurationMs) / (filledCount - 1))
      .floor();
}

int getReferenceRevealDelayMs(int filledIndex, int filledCount) {
  if (filledIndex <= 0 || filledCount <= 0) {
    return 0;
  }

  return filledIndex * getReferenceRevealStaggerMs(filledCount);
}

int getReferenceRevealTotalMs(int filledCount) {
  if (filledCount <= 0) {
    return 0;
  }

  if (filledCount == 1) {
    return fruitPopDurationMs;
  }

  return (filledCount - 1) * getReferenceRevealStaggerMs(filledCount) +
      fruitPopDurationMs;
}

const targetGridRevealGapMs = 180;
const targetGridPopMs = 280;

int getTargetGridRevealStartMs(int filledCount) {
  return getReferenceRevealTotalMs(filledCount) + targetGridRevealGapMs;
}

int getPoolRevealStartMs(int filledCount) {
  return getTargetGridRevealStartMs(filledCount) + targetGridPopMs;
}

int getGridMatchInteractionReadyMs(int filledCount, int poolCount) {
  return getPoolRevealStartMs(filledCount) + getAnswerRevealTotalMs(poolCount);
}
