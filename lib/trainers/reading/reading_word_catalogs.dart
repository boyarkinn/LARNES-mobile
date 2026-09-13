import 'package:larnes_mobile/trainers/reading/letter_model.dart';
import 'package:larnes_mobile/trainers/shared/first_words/catalog.dart';
import 'package:larnes_mobile/trainers/shared/first_words/resolve_first_word.dart';

final fillGapWordSlugs = [for (final word in firstWords) word.slug];

String normalizeFillGapWordLabel(String label) {
  return label.replaceFirst(RegExp(r'\d+$'), '');
}

String getFillGapWordLabel(String slug) {
  final word = getFirstWord(slug);
  return word == null ? 'аист' : normalizeFillGapWordLabel(word.label);
}

String? getFillGapWordImageSrc(String slug) {
  return getFirstWordImageWidgetAsset(slug);
}

const wordLinkLabels = {
  'airplane': 'Аэроплан',
  'apple-fruit': 'Яблоко',
  'banana': 'Банан',
  'bear': 'Медведь',
  'bus': 'Автобус',
  'butterfly': 'Бабочка',
  'car': 'Машина',
  'cat': 'Кот',
  'cloud': 'Облако',
  'crocodile': 'Крокодил',
  'dolphin': 'Дельфин',
  'duck': 'Утка',
  'elephant': 'Слон',
  'fish': 'Рыба',
  'fox': 'Лиса',
  'frog': 'Лягушка',
  'giraffe': 'Жираф',
  'goose': 'Гусь',
  'house': 'Дом',
  'lemon': 'Лимон',
  'lion': 'Лев',
  'milk': 'Молоко',
  'mushroom': 'Гриб',
  'nose': 'Нос',
  'owl': 'Сова',
  'pear': 'Груша',
  'pineapple': 'Ананас',
  'rabbit': 'Кролик',
  'rose': 'Роза',
  'snake': 'Змея',
  'stork': 'Аист',
  'tiger': 'Тигр',
  'tortoise': 'Черепаха',
  'train': 'Поезд',
  'watermelon': 'Арбуз',
  'wolf': 'Волк',
};

const firstByImageWordSlugs = [
  'stork',
  'cat',
  'house',
  'apple',
  'lemon',
  'owl',
  'fish',
  'mushroom',
];

const firstByImageWordLabels = {
  'apple': 'Яблоко',
  'cat': 'Кот',
  'fish': 'Рыба',
  'house': 'Дом',
  'lemon': 'Лимон',
  'mushroom': 'Гриб',
  'owl': 'Сова',
  'stork': 'Аист',
};

const maxLetterChoices = 8;
const minWordLinkItems = 3;
const maxWordLinkItems = 8;
const minWordLinkCorrectItems = 2;
const minPairCount = 2;
const maxPairCount = 12;
const minGridFilledCount = 1;

bool isFirstByImageWordSlug(String value) {
  return firstByImageWordSlugs.contains(value);
}

String normalizeFirstByImageWordSlug(String value) {
  return isFirstByImageWordSlug(value) ? value : 'stork';
}

String getFirstByImageWordLabel(String slug) {
  return firstByImageWordLabels[normalizeFirstByImageWordSlug(slug)] ?? 'Аист';
}

/// Путь к изображению слова; null — режим заглушки (текст на экране).
String? getFirstByImageWordImageSrc(String slug) {
  return null;
}

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

bool _isWordEligibleForPractice(String label, List<String> practiceLetters) {
  for (final practiceLetter in practiceLetters) {
    final normalizedPractice = _normalizeFillGapLetter(practiceLetter);
    for (var index = 0; index < label.length; index++) {
      final char = label[index];
      if (!_isFillGapRussianLetter(char)) {
        continue;
      }
      if (_normalizeFillGapLetter(char) == normalizedPractice) {
        return true;
      }
    }
  }
  return false;
}

int countEligibleFillGapWords(List<String> practiceLetters) {
  final eligibleLabels = <String>{};
  for (final word in firstWords) {
    final label = normalizeFillGapWordLabel(word.label);
    if (_isWordEligibleForPractice(label, practiceLetters)) {
      eligibleLabels.add(label.toLowerCase());
    }
  }
  return eligibleLabels.length;
}

String getWordLinkFirstLetter(String slug) {
  final label = wordLinkLabels[slug];
  if (label == null || label.isEmpty) {
    return 'А';
  }
  return normalizeTargetLetter(label[0]);
}

String getWordLinkLabel(String slug) {
  return wordLinkLabels[slug] ?? 'Аист';
}

/// Путь к изображению предмета; null — режим заглушки (текст на экране).
String? getWordLinkImageSrc(String slug) {
  return null;
}

List<String> getWordsByFirstLetter(String letter) {
  final normalized = normalizeTargetLetter(letter);
  return wordLinkLabels.entries
      .where((entry) => getWordLinkFirstLetter(entry.key) == normalized)
      .map((entry) => entry.key)
      .toList();
}

List<String> getWordsNotStartingWith(String letter) {
  final normalized = normalizeTargetLetter(letter);
  return wordLinkLabels.entries
      .where((entry) => getWordLinkFirstLetter(entry.key) != normalized)
      .map((entry) => entry.key)
      .toList();
}

int countCorrectWordLinkItems(int entityCount, int correctPoolSize) {
  final desired = entityCount - 1;
  final target = desired < minWordLinkCorrectItems
      ? minWordLinkCorrectItems
      : desired;
  return correctPoolSize < target ? correctPoolSize : target;
}

bool canBuildWordLinkRound(String letter, int entityCount) {
  if (entityCount < minWordLinkItems || entityCount > maxWordLinkItems) {
    return false;
  }
  final normalized = normalizeTargetLetter(letter);
  final correctPool = getWordsByFirstLetter(normalized);
  final correctCount = countCorrectWordLinkItems(
    entityCount,
    correctPool.length,
  );
  final distractorPool = getWordsNotStartingWith(normalized);
  return correctPool.length >= minWordLinkCorrectItems &&
      distractorPool.length >= entityCount - correctCount;
}
