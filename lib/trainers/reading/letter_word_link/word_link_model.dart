import 'package:larnes_mobile/trainers/reading/letter_model.dart';
import 'package:larnes_mobile/trainers/reading/reading_word_catalogs.dart';
import 'package:larnes_mobile/trainers/shared/seeded_rng.dart';

/// Web: `platform/src/trainers/reading/letter-word-link/model.ts`

const minWordLinkItemCount = minWordLinkItems;
const maxWordLinkItemCount = maxWordLinkItems;

class WordLinkItem {
  const WordLinkItem({
    required this.displayLabel,
    required this.id,
    required this.isMatch,
    required this.label,
    required this.slug,
  });

  final String displayLabel;
  final String id;
  final bool isMatch;
  final String label;
  final String slug;
}

class WordLinkRound {
  const WordLinkRound({
    required this.displayLetter,
    required this.letter,
    required this.wordItems,
  });

  final String displayLetter;
  final String letter;
  final List<WordLinkItem> wordItems;
}

class WordLinkConnection {
  const WordLinkConnection({
    required this.rightId,
    required this.slug,
  });

  final String rightId;
  final String slug;
}

class BuildWordLinkRoundInput {
  const BuildWordLinkRoundInput({
    required this.entityCount,
    required this.letter,
    required this.letterCase,
    required this.seed,
    required this.wordCase,
  });

  final int entityCount;
  final String letter;
  final String letterCase;
  final int seed;
  final String wordCase;
}

int countCorrectWordLinkRoundItems(int entityCount, int correctPoolSize) {
  return countCorrectWordLinkItems(entityCount, correctPoolSize);
}

WordLinkRound buildWordLinkRound(BuildWordLinkRoundInput input) {
  final letter = normalizeTargetLetter(input.letter);
  final rng = createSeededRng(input.seed);
  final correctPool = getWordsByFirstLetter(letter);
  final distractorPool = getWordsNotStartingWith(letter);
  final correctCount =
      countCorrectWordLinkItems(input.entityCount, correctPool.length);
  final distractorCount = input.entityCount - correctCount;
  final selectedCorrect = _pickUniqueSlugs(correctPool, correctCount, rng);
  final selectedDistractors =
      _pickUniqueSlugs(distractorPool, distractorCount, rng);
  final selectedSlugs =
      _shuffleItems([...selectedCorrect, ...selectedDistractors], rng);

  final wordItems = <WordLinkItem>[
    for (var index = 0; index < selectedSlugs.length; index++)
      WordLinkItem(
        displayLabel: applyWordCase(
          getWordLinkLabel(selectedSlugs[index]),
          input.wordCase,
        ),
        id: 'word-$index-${selectedSlugs[index]}',
        isMatch: getWordLinkFirstLetter(selectedSlugs[index]) == letter,
        label: getWordLinkLabel(selectedSlugs[index]),
        slug: selectedSlugs[index],
      ),
  ];

  return WordLinkRound(
    displayLetter: applyLetterCase(letter, input.letterCase),
    letter: letter,
    wordItems: wordItems,
  );
}

int buildWordLinkRoundSeed(List<Object> parts) {
  return hashParamsSeed([...parts, 'word-link']);
}

bool isCorrectWordLink(WordLinkItem item, String letter) {
  return item.isMatch &&
      getWordLinkFirstLetter(item.slug) == normalizeTargetLetter(letter);
}

bool isWordLinkRoundComplete(
  List<WordLinkConnection> connections,
  WordLinkRound round,
) {
  final required = round.wordItems.where((item) => item.isMatch).toList();

  if (required.isEmpty) {
    return false;
  }

  final connectedIds =
      connections.map((connection) => connection.rightId).toSet();

  return required.every((item) => connectedIds.contains(item.id));
}

String normalizeWordLinkRoundLetter(String letter) {
  return normalizeTargetLetter(letter);
}

String getWordLinkAudioStubMessage(String displayLabel) {
  return 'Озвучка «$displayLabel» — в следующем цикле.';
}

List<String> _pickUniqueSlugs(
  List<String> pool,
  int count,
  double Function() rng,
) {
  return _shuffleItems([...pool], rng).take(count).toList();
}

List<T> _shuffleItems<T>(List<T> items, double Function() rng) {
  final next = [...items];

  for (var index = next.length - 1; index > 0; index--) {
    final swapIndex = (rng() * (index + 1)).floor();
    final temp = next[index];
    next[index] = next[swapIndex];
    next[swapIndex] = temp;
  }

  return next;
}
