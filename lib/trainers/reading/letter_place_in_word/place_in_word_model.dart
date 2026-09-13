import 'dart:ui';

import 'package:larnes_mobile/trainers/reading/letter_model.dart';
import 'package:larnes_mobile/trainers/reading/reading_word_catalogs.dart';
import 'package:larnes_mobile/trainers/shared/seeded_rng.dart';

/// Web: `platform/src/trainers/reading/letter-place-in-word/model.ts`

class OmitResolution {
  const OmitResolution({required this.omitIndex, required this.omitLetter});

  final int omitIndex;
  final String omitLetter;

  @override
  bool operator ==(Object other) {
    return other is OmitResolution &&
        other.omitIndex == omitIndex &&
        other.omitLetter == omitLetter;
  }

  @override
  int get hashCode => Object.hash(omitIndex, omitLetter);
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

  LetterPoolTile copyWith({String? id, String? letter, bool? used}) {
    return LetterPoolTile(
      id: id ?? this.id,
      letter: letter ?? this.letter,
      used: used ?? this.used,
    );
  }
}

OmitResolution? resolveOmitForWord(String label, List<String> practiceLetters) {
  for (final practiceLetter in practiceLetters) {
    final normalizedPractice = practiceLetter.toUpperCase();

    for (var index = 0; index < label.length; index++) {
      final char = label[index];

      if (!parseFillGapPracticeLetters(char).contains(char.toUpperCase())) {
        continue;
      }

      if (char.toUpperCase() == normalizedPractice) {
        return OmitResolution(omitIndex: index, omitLetter: normalizedPractice);
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
  final shuffledEligible = _shuffleItems(
    fillGapWordSlugs
        .where(
          (slug) => isWordEligibleForPractice(
            getFillGapWordLabel(slug),
            practiceLetters,
          ),
        )
        .toList(),
    rng,
  );
  final seenLabels = <String>{};
  final eligible = shuffledEligible.where((slug) {
    final label = getFillGapWordLabel(slug).toLowerCase();
    return seenLabels.add(label);
  }).toList();

  if (eligible.length < entityCount) {
    return const [];
  }

  return eligible.take(entityCount).toList();
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
  int? seed,
  double Function()? random,
  required String wordCase,
}) {
  if (random == null && seed == null) {
    throw ArgumentError('Either random or seed must be provided.');
  }
  final rng = random ?? createSeededRng(seed!);
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
    for (final letter in [
      ...russianLettersUpper.take(6),
      'Ё',
      ...russianLettersUpper.skip(6),
    ])
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

  return _shuffleItems([
    ...correctTiles,
    ...distractors,
  ], rng).map((tile) => tile.copyWith(used: false)).toList();
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
