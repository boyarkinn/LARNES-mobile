const maxFillGapWordLength = 4;

const maxLetterChoices = 8;
const minWordLinkItems = 3;
const maxWordLinkItems = 8;
const minWordLinkCorrectItems = 2;
const minPairCount = 2;
const maxPairCount = 12;
const minGridFilledCount = 1;

bool canFitLetterChoices(int distractorCount) {
  return distractorCount >= 0 && 1 + distractorCount <= maxLetterChoices;
}

bool canUsePairCount(List<String> letters, int pairCount) {
  return pairCount >= minPairCount &&
      pairCount <= maxPairCount &&
      letters.length >= pairCount;
}

bool isValidGridSize(int gridSize) {
  return gridSize == 2 || gridSize == 3;
}

int getMaxFilledCount(int gridSize) {
  return gridSize * gridSize;
}

bool isValidFilledCount(int gridSize, int filledCount) {
  final maxFilled = getMaxFilledCount(gridSize);
  return filledCount >= minGridFilledCount && filledCount <= maxFilled;
}

const _fillGapRussianLettersUpper = [
  'А',
  'Б',
  'В',
  'Г',
  'Д',
  'Е',
  'Ё',
  'Ж',
  'З',
  'И',
  'Й',
  'К',
  'Л',
  'М',
  'Н',
  'О',
  'П',
  'Р',
  'С',
  'Т',
  'У',
  'Ф',
  'Х',
  'Ц',
  'Ч',
  'Ш',
  'Щ',
  'Ъ',
  'Ы',
  'Ь',
  'Э',
  'Ю',
  'Я',
];

String _normalizeFillGapLetter(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? '' : trimmed[0].toUpperCase();
}

bool _isFillGapRussianLetter(String value) {
  return _fillGapRussianLettersUpper.contains(_normalizeFillGapLetter(value));
}

List<String> parseFillGapPracticeLetters(String raw) {
  final letters = <String>[];
  final seen = <String>{};
  for (final part in raw.split(RegExp(r'[,;\s]+'))) {
    final normalized = _normalizeFillGapLetter(part);
    if (_isFillGapRussianLetter(normalized) && seen.add(normalized)) {
      letters.add(normalized);
    }
  }
  return letters;
}

int countCorrectWordLinkItems(int entityCount, int correctPoolSize) {
  final desired = entityCount - 1;
  final target = desired < minWordLinkCorrectItems
      ? minWordLinkCorrectItems
      : desired;
  return correctPoolSize < target ? correctPoolSize : target;
}
