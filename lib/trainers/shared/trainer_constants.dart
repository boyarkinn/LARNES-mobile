int getMaxValueForRods(int totalRods) {
  if (totalRods < 1) {
    return 0;
  }
  var maxValue = 1;
  for (var i = 0; i < totalRods; i++) {
    maxValue *= 10;
  }
  return maxValue - 1;
}

const maxDigitFieldTokens = 28;
const maxFruitFieldTokens = 30;
const maxDotChoice = 3;
const maxShopCoins = 12;
const maxShopPrice = 9;
const minMatchPairs = 2;
const maxMatchPairs = 4;

const fruitSlugs = [
  'apple',
  'banana',
  'cherry',
  'grape',
  'orange',
  'peach',
  'pear',
  'plum',
  'strawberry',
  'watermelon',
];

const shopItemSlugs = [
  'candy',
  'ice-cream',
  'car',
  'doll',
  'banana',
];

bool isTargetCountInAnswerRange(int targetCount, int answerRangeStart) {
  return targetCount >= answerRangeStart && targetCount <= answerRangeStart + 3;
}

bool isMissingPartInDigitRange(int missingPart, int answerRangeStart) {
  return missingPart >= answerRangeStart && missingPart <= answerRangeStart + 3;
}

bool isMissingPartInDotRange(int missingPart) {
  return missingPart >= 0 && missingPart <= maxDotChoice;
}

bool isCoinCountValid(int coinCount, int price) {
  return coinCount >= price && coinCount >= 1 && coinCount <= maxShopCoins;
}

bool areFlashcardValuesValid(List<int> values, int totalRods) {
  if (values.length < minMatchPairs || values.length > maxMatchPairs) {
    return false;
  }
  final maxValue = getMaxValueForRods(totalRods);
  final unique = values.toSet();
  return unique.length == values.length && values.every((value) => value <= maxValue);
}
