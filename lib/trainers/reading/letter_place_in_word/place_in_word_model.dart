import 'dart:ui';

import 'package:larnes_mobile/trainers/reading/letter_model.dart';
import 'package:larnes_mobile/trainers/reading/reading_word_catalogs.dart';
import 'package:larnes_mobile/trainers/shared/seeded_rng.dart';

/// Web: `platform/src/trainers/reading/letter-place-in-word/model.ts`

class OmitResolution {
  const OmitResolution({
    required this.omitIndex,
    required this.omitLetter,
  });

  final int omitIndex;
  final String omitLetter;
}

class FillGapTask {
  const FillGapTask({
    required this.after,
    required this.before,
    required this.correctLetter,
    required this.displayWord,
    required this.omitIndex,
    required this.slug,
  });

  final String after;
  final String before;
  final String correctLetter;
  final String displayWord;
  final int omitIndex;
  final String slug;
}

class LetterPoolTile {
  const LetterPoolTile({
    required this.id,
    required this.letter,
    required this.used,
  });

  final String id;
  final String letter;
  final bool used;

  LetterPoolTile copyWith({
    String? id,
    String? letter,
    bool? used,
  }) {
    return LetterPoolTile(
      id: id ?? this.id,
      letter: letter ?? this.letter,
      used: used ?? this.used,
    );
  }
}

OmitResolution? resolveOmitForWord(
  String label,
  List<String> practiceLetters,
) {
  for (final practiceLetter in practiceLetters) {
    final normalizedPractice = normalizeTargetLetter(practiceLetter);

    for (var index = 0; index < label.length; index++) {
      final char = label[index];

      if (!isRussianLetterWithoutYo(char)) {
        continue;
      }

      if (normalizeTargetLetter(char) == normalizedPractice) {
        return OmitResolution(
          omitIndex: index,
          omitLetter: normalizedPractice,
        );
      }
    }
  }

  return null;
}

bool isWordEligibleForPractice(String label, List<String> practiceLetters) {
  return resolveOmitForWord(label, practiceLetters) != null;
}

int countEligibleWords(List<String> practiceLetters) {
  return countEligibleFillGapWords(practiceLetters);
}

List<String> pickWordsForRound({
  required int entityCount,
  required List<String> practiceLetters,
  required double Function() rng,
}) {
  final eligible = fillGapWordSlugs
      .where(
        (slug) => isWordEligibleForPractice(
          getFillGapWordLabel(slug),
          practiceLetters,
        ),
      )
      .toList();

  if (eligible.length < entityCount) {
    return const [];
  }

  return _shuffleItems(eligible, rng).take(entityCount).toList();
}

FillGapTask buildFillGapTask(
  String slug,
  List<String> practiceLetters,
  String wordCase,
  String letterCase,
) {
  final label = getFillGapWordLabel(slug);
  final resolution = resolveOmitForWord(label, practiceLetters);

  if (resolution == null) {
    throw StateError('Word "$slug" is not eligible for practice letters');
  }

  final displayWord = applyWordCase(label, wordCase);
  final correctLetter = applyLetterCase(resolution.omitLetter, letterCase);

  return FillGapTask(
    after: displayWord.substring(resolution.omitIndex + 1),
    before: displayWord.substring(0, resolution.omitIndex),
    correctLetter: correctLetter,
    displayWord: displayWord,
    omitIndex: resolution.omitIndex,
    slug: slug,
  );
}

List<FillGapTask> buildFillGapTasks({
  required int entityCount,
  required String letterCase,
  required List<String> practiceLetters,
  required int seed,
  required String wordCase,
}) {
  final rng = createSeededRng(seed);
  final slugs = pickWordsForRound(
    entityCount: entityCount,
    practiceLetters: practiceLetters,
    rng: rng,
  );

  return [
    for (final slug in slugs)
      buildFillGapTask(slug, practiceLetters, wordCase, letterCase),
  ];
}

List<LetterPoolTile> buildLetterPoolTiles({
  required int distractorCount,
  required String letterCase,
  required double Function() rng,
  required List<FillGapTask> tasks,
}) {
  final correctTiles = [
    for (var index = 0; index < tasks.length; index++)
      LetterPoolTile(
        id: 'correct-$index',
        letter: tasks[index].correctLetter,
        used: false,
      ),
  ];

  final usedLetters = correctTiles.map((tile) => tile.letter).toSet();
  final distractorPool = [
    for (final letter in russianLettersUpper)
      if (!usedLetters.contains(applyLetterCase(letter, letterCase)))
        applyLetterCase(letter, letterCase),
  ];

  final distractors = <LetterPoolTile>[];

  while (distractors.length < distractorCount && distractorPool.isNotEmpty) {
    final pick = distractorPool[(rng() * distractorPool.length).floor()];
    distractors.add(
      LetterPoolTile(
        id: 'distractor-${distractors.length}',
        letter: pick,
        used: false,
      ),
    );
  }

  return _shuffleItems([...correctTiles, ...distractors], rng)
      .map((tile) => tile.copyWith(used: false))
      .toList();
}

int buildPlaceInWordRoundSeed(List<Object> parts) {
  return hashParamsSeed([...parts, 'place-in-word']);
}

bool isPointInsideRect(double x, double y, Rect rect) {
  return x >= rect.left && x <= rect.right && y >= rect.top && y <= rect.bottom;
}

List<T> _shuffleItems<T>(List<T> items, double Function() rng) {
  final next = List<T>.from(items);

  for (var index = next.length - 1; index > 0; index--) {
    final swapIndex = (rng() * (index + 1)).floor();
    final temp = next[index];
    next[index] = next[swapIndex];
    next[swapIndex] = temp;
  }

  return next;
}
