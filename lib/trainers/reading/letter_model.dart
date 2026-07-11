const maxLetterFieldTokens = 28;
const maxPoolLetters = 12;
const maxEntityCount = 6;
const maxPracticeLettersNameAloud = 20;

const letterCaseValues = ['upper', 'lower'];
const dotModeValues = ['numbered', 'free'];
const marqueeSpeedValues = ['slow', 'medium', 'fast'];

const russianLettersUpper = [
  'А', 'Б', 'В', 'Г', 'Д', 'Е', 'Ж', 'З', 'И', 'Й', 'К', 'Л', 'М', 'Н', 'О', 'П',
  'Р', 'С', 'Т', 'У', 'Ф', 'Х', 'Ц', 'Ч', 'Ш', 'Щ', 'Ъ', 'Ы', 'Ь', 'Э', 'Ю', 'Я',
];

final _russianLetterUpperSet = Set<String>.from(russianLettersUpper);

bool isRussianLetterWithoutYo(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return false;
  }
  final upper = _toRussianUpper(trimmed[0]);
  return _russianLetterUpperSet.contains(upper);
}

String normalizeTargetLetter(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty || !isRussianLetterWithoutYo(trimmed)) {
    return 'А';
  }
  return _toRussianUpper(trimmed[0]);
}

String applyLetterCase(String letter, String letterCase) {
  if (letterCase == 'lower') {
    return letter.toLowerCase();
  }
  return letter.toUpperCase();
}

bool canFitLetterField(int targetCount, int distractorCount) {
  return targetCount >= 1 &&
      distractorCount >= 0 &&
      targetCount + distractorCount <= maxLetterFieldTokens;
}

bool canFitSoundFindField(int distractorCount) {
  return canFitLetterField(1, distractorCount);
}

bool canFitLetterPool(int entityCount, int distractorCount) {
  return entityCount >= 1 &&
      distractorCount >= 0 &&
      entityCount + distractorCount <= maxPoolLetters;
}

List<String> parsePracticeLetters(String raw) {
  final parts = raw.split(RegExp(r'[,;\s]+')).map((part) => part.trim()).where((part) => part.isNotEmpty);
  final letters = <String>[];
  final seen = <String>{};

  for (final part in parts) {
    final normalized = normalizeTargetLetter(part);
    if (!isRussianLetterWithoutYo(normalized) || seen.contains(normalized)) {
      continue;
    }
    seen.add(normalized);
    letters.add(normalized);
  }

  return letters;
}

String formatPracticeLetters(List<String> letters) {
  return letters.join(',');
}

String? parseLetterCase(dynamic raw, {String fallback = 'upper'}) {
  if (raw == null) {
    return fallback;
  }
  final value = raw.toString();
  if (letterCaseValues.contains(value)) {
    return value;
  }
  return null;
}

String _toRussianUpper(String char) {
  const lowerToUpper = {
    'а': 'А', 'б': 'Б', 'в': 'В', 'г': 'Г', 'д': 'Д', 'е': 'Е', 'ж': 'Ж', 'з': 'З',
    'и': 'И', 'й': 'Й', 'к': 'К', 'л': 'Л', 'м': 'М', 'н': 'Н', 'о': 'О', 'п': 'П',
    'р': 'Р', 'с': 'С', 'т': 'Т', 'у': 'У', 'ф': 'Ф', 'х': 'Х', 'ц': 'Ц', 'ч': 'Ч',
    'ш': 'Ш', 'щ': 'Щ', 'ъ': 'Ъ', 'ы': 'Ы', 'ь': 'Ь', 'э': 'Э', 'ю': 'Ю', 'я': 'Я',
  };
  return lowerToUpper[char] ?? char.toUpperCase();
}

String normalizeDrawShowLetter(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return 'А';
  }
  return _toRussianUpper(trimmed[0]);
}

String applyWordCase(String label, String wordCase) {
  if (wordCase == 'lower') {
    return label.toLowerCase();
  }
  return label;
}

bool isOrientationPickableLetter(String letter) {
  return normalizeTargetLetter(letter) != 'О';
}

bool isValidOddLetterParam(String mainLetter, Object oddLetter) {
  if (oddLetter == 'random') {
    return true;
  }
  final main = normalizeTargetLetter(mainLetter);
  final odd = normalizeTargetLetter(oddLetter.toString());
  return odd != main;
}
