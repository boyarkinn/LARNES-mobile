/// Web v2: `platform/src/trainers/math/fruit-count-tap/fruit-reveal.ts`

const fruitPopDurationMs = 250;
const kFruitPopDurationMs = fruitPopDurationMs;

const fruitRevealTotalBudgetMs = 2000;
const answerRevealTotalBudgetMs = 700;

int getFruitRevealStaggerMs(int count) {
  if (count <= 1) {
    return 0;
  }

  return ((fruitRevealTotalBudgetMs - fruitPopDurationMs) / (count - 1)).floor();
}

int getFruitRevealDelayMs(int index, int count) {
  if (index <= 0 || count <= 0) {
    return 0;
  }

  return index * getFruitRevealStaggerMs(count);
}

int getFruitRevealTotalMs(int count) {
  if (count <= 0) {
    return 0;
  }

  if (count == 1) {
    return fruitPopDurationMs;
  }

  return (count - 1) * getFruitRevealStaggerMs(count) + fruitPopDurationMs;
}

int getAnswerRevealStaggerMs(int count) {
  if (count <= 1) {
    return 0;
  }

  return ((answerRevealTotalBudgetMs - fruitPopDurationMs) / (count - 1)).floor();
}

int getAnswerRevealDelayMs(int index, int count) {
  if (index <= 0 || count <= 0) {
    return 0;
  }

  return index * getAnswerRevealStaggerMs(count);
}

int getAnswerRevealTotalMs(int count) {
  if (count <= 0) {
    return 0;
  }

  if (count == 1) {
    return fruitPopDurationMs;
  }

  return (count - 1) * getAnswerRevealStaggerMs(count) + fruitPopDurationMs;
}
