/// Web: `platform/src/trainers/reading/letter-first-by-sound/model.ts`

import 'package:larnes_mobile/trainers/reading/letter_model.dart';
import 'package:larnes_mobile/trainers/shared/first_words/resolve_first_word.dart';
import 'package:larnes_mobile/trainers/shared/seeded_rng.dart';

const maxLetterChoices = 8;
const maxFirstBySoundPracticeLetters = 20;
const minFirstBySoundRounds = 1;
const maxFirstBySoundRounds = 12;
const defaultFirstBySoundRounds = 6;
const defaultFirstBySoundPracticeLetters = 'А,Д,Н';

class FirstBySoundRound {
  const FirstBySoundRound({
    required this.firstLetter,
    required this.slug,
  });

  final String firstLetter;
  final String slug;
}

class BuildLetterChoicesInput {
  const BuildLetterChoicesInput({
    required this.distractorCount,
    required this.firstLetter,
    required this.letterCase,
    required this.rng,
  });

  final int distractorCount;
  final String firstLetter;
  final String letterCase;
  final double Function() rng;
}

bool canFitFirstBySoundChoices(int distractorCount) {
  return distractorCount >= 0 && 1 + distractorCount <= maxLetterChoices;
}

List<String> resolveFirstBySoundPracticeLetters([String? practiceLettersRaw]) {
  final raw = practiceLettersRaw?.trim() ?? '';
  return parsePracticeLetters(
    raw.isEmpty ? defaultFirstBySoundPracticeLetters : raw,
  );
}

bool hasFirstWordsForLetters(List<String> letters) {
  return letters.isNotEmpty &&
      letters.every((letter) => listFirstWordsByLetter(letter).isNotEmpty);
}

bool isValidFirstBySoundPracticeLetters([String? practiceLettersRaw]) {
  final letters = parsePracticeLetters(practiceLettersRaw?.trim() ?? '');
  return letters.isNotEmpty &&
      letters.length <= maxFirstBySoundPracticeLetters &&
      hasFirstWordsForLetters(letters);
}

List<String> cyclePracticeLetters(List<String> letters, int rounds) {
  if (letters.isEmpty || rounds <= 0) {
    return const [];
  }

  return [
    for (var index = 0; index < rounds; index++) letters[index % letters.length],
  ];
}

String? pickWordSlugForLetter(
  String letter,
  String? previousSlug,
  double Function() rng,
) {
  final pool = listFirstWordsByLetter(letter);
  if (pool.isEmpty) {
    return null;
  }

  final candidates = previousSlug == null
      ? pool
      : pool.where((word) => word.slug != previousSlug).toList();
  final pickFrom = candidates.isNotEmpty ? candidates : pool;
  return pickFrom[(rng() * pickFrom.length).floor()].slug;
}

List<FirstBySoundRound> buildRoundPlan({
  required List<String> letters,
  required double Function() rng,
  required int rounds,
}) {
  final cycle = cyclePracticeLetters(letters, rounds);
  final plan = <FirstBySoundRound>[];
  String? previousSlug;

  for (final letter in cycle) {
    final slug = pickWordSlugForLetter(letter, previousSlug, rng);
    if (slug == null) {
      continue;
    }

    plan.add(FirstBySoundRound(firstLetter: letter, slug: slug));
    previousSlug = slug;
  }

  return plan;
}

List<String> buildLetterChoices(BuildLetterChoicesInput input) {
  final targetLetter = normalizeTargetLetter(input.firstLetter);
  final target = applyLetterCase(targetLetter, input.letterCase);
  final pool = russianLettersUpper
      .where((letter) => letter != targetLetter)
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

bool isCorrectLetterChoice(
  String firstLetter,
  String letterCase,
  String selectedLetter,
) {
  return applyLetterCase(normalizeTargetLetter(firstLetter), letterCase) ==
      selectedLetter;
}

int buildFirstBySoundPlanSeed({
  required String practiceLetters,
  required int rounds,
  required int layoutSalt,
}) {
  return hashParamsSeed([
    practiceLetters,
    rounds,
    layoutSalt,
    'first-by-sound',
  ]);
}

int buildFirstBySoundChoicesSeed({
  required String slug,
  required String letterCase,
  required int distractorCount,
  required int layoutSalt,
  required int roundIndex,
}) {
  return hashParamsSeed([
    slug,
    letterCase,
    distractorCount,
    layoutSalt,
    roundIndex,
    'first-by-sound-choices',
  ]);
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
