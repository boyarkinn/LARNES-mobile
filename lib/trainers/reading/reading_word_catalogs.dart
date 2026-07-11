import 'package:larnes_mobile/trainers/reading/letter_model.dart';

const fillGapWordLabels = {
  'apple': 'Яблоко',
  'bear': 'Мишка',
  'bridge': 'Мост',
  'cat': 'Кот',
  'door': 'Дверь',
  'duck': 'Утка',
  'fish': 'Рыба',
  'hand': 'Рука',
  'house': 'Дом',
  'juice': 'Сок',
  'lemon': 'Лимон',
  'mama': 'Мама',
  'nose': 'Нос',
  'owl': 'Сова',
  'puddle': 'Лужа',
  'rose': 'Роза',
  'stork': 'Аист',
  'watermelon': 'Арбуз',
};

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

bool _isWordEligibleForPractice(String label, List<String> practiceLetters) {
  for (final practiceLetter in practiceLetters) {
    final normalizedPractice = normalizeTargetLetter(practiceLetter);
    for (var index = 0; index < label.length; index++) {
      final char = label[index];
      if (!isRussianLetterWithoutYo(char)) {
        continue;
      }
      if (normalizeTargetLetter(char) == normalizedPractice) {
        return true;
      }
    }
  }
  return false;
}

int countEligibleFillGapWords(List<String> practiceLetters) {
  var count = 0;
  for (final label in fillGapWordLabels.values) {
    if (_isWordEligibleForPractice(label, practiceLetters)) {
      count += 1;
    }
  }
  return count;
}

String getWordLinkFirstLetter(String slug) {
  final label = wordLinkLabels[slug];
  if (label == null || label.isEmpty) {
    return 'А';
  }
  return normalizeTargetLetter(label[0]);
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
  final target = desired < minWordLinkCorrectItems ? minWordLinkCorrectItems : desired;
  return correctPoolSize < target ? correctPoolSize : target;
}

bool canBuildWordLinkRound(String letter, int entityCount) {
  if (entityCount < minWordLinkItems || entityCount > maxWordLinkItems) {
    return false;
  }
  final normalized = normalizeTargetLetter(letter);
  final correctPool = getWordsByFirstLetter(normalized);
  final correctCount = countCorrectWordLinkItems(entityCount, correctPool.length);
  final distractorPool = getWordsNotStartingWith(normalized);
  return correctPool.length >= minWordLinkCorrectItems &&
      distractorPool.length >= entityCount - correctCount;
}
