import 'package:larnes_mobile/trainers/reading/letter_model.dart';
import 'package:larnes_mobile/trainers/reading/reading_word_catalogs.dart';
import 'package:larnes_mobile/trainers/shared/seeded_rng.dart';

/// Web: `platform/src/trainers/reading/letter-first-by-image/model.ts`

class BuildLetterChoicesInput {
  const BuildLetterChoicesInput({
    required this.distractorCount,
    required this.firstLetter,
    required this.letterCase,
    required this.rng,
    required this.wordSlug,
  });

  final int distractorCount;
  final String firstLetter;
  final String letterCase;
  final double Function() rng;
  final String wordSlug;
}

String getFirstLetterFromWordSlug(String slug) {
  final label = getFirstByImageWordLabel(slug);
  final trimmed = label.trim();
  if (trimmed.isEmpty) {
    return 'А';
  }

  final firstChar = trimmed[0];
  if (!isRussianLetterWithoutYo(firstChar)) {
    return 'А';
  }

  return normalizeTargetLetter(firstChar);
}

String getWordAudioStubMessage(String displayWord) {
  return 'Заглушка аудио: слово «$displayWord»';
}

List<String> buildLetterChoices(BuildLetterChoicesInput input) {
  final target = applyLetterCase(
    normalizeTargetLetter(input.firstLetter),
    input.letterCase,
  );
  final normalizedFirst = normalizeTargetLetter(input.firstLetter);
  final pool = russianLettersUpper
      .where((letter) => letter != normalizedFirst)
      .map((letter) => applyLetterCase(letter, input.letterCase))
      .toList();

  final distractors = <String>[];
  final used = <String>{target};

  while (distractors.length < input.distractorCount && pool.isNotEmpty) {
    final pick = pool[(input.rng() * pool.length).floor()];

    if (!used.contains(pick)) {
      distractors.add(pick);
      used.add(pick);
    }
  }

  return _shuffleLetters([target, ...distractors], input.rng);
}

String resolveFirstByImageWordSlug(String value) {
  return normalizeFirstByImageWordSlug(value);
}

int buildFirstByImageChoicesSeed({
  required String wordSlug,
  required String wordCase,
  required String letterCase,
  required int distractorCount,
  required int layoutSalt,
}) {
  return hashParamsSeed([
    wordSlug,
    wordCase,
    letterCase,
    distractorCount,
    layoutSalt,
    'first-by-image',
  ]);
}

bool isCorrectLetterChoice(
  String firstLetter,
  String letterCase,
  String selectedLetter,
) {
  return applyLetterCase(normalizeTargetLetter(firstLetter), letterCase) ==
      selectedLetter;
}

List<String> _shuffleLetters(List<String> items, double Function() rng) {
  final next = [...items];

  for (var index = next.length - 1; index > 0; index--) {
    final swapIndex = (rng() * (index + 1)).floor();
    final temp = next[index];
    next[index] = next[swapIndex];
    next[swapIndex] = temp;
  }

  return next;
}
