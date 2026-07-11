/// Web v2: `platform/src/trainers/math/number-row-show/number-row-reveal.ts`

const numberRowPopMs = 250;
const numberRowRevealBudgetMs = 2000;
const numberRowDigitCount = 10;

int getNumberRowRevealStaggerMs(int count) {
  if (count <= 1) {
    return 0;
  }

  return ((numberRowRevealBudgetMs - numberRowPopMs) / (count - 1)).floor();
}

int getNumberRowRevealDelayMs(int index, [int count = numberRowDigitCount]) {
  if (index <= 0 || count <= 0) {
    return 0;
  }

  return index * getNumberRowRevealStaggerMs(count);
}

int getNumberRowRevealTotalMs([int count = numberRowDigitCount]) {
  if (count <= 0) {
    return 0;
  }

  if (count == 1) {
    return numberRowPopMs;
  }

  return (count - 1) * getNumberRowRevealStaggerMs(count) + numberRowPopMs;
}
