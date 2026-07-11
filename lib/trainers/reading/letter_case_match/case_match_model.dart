import 'package:larnes_mobile/trainers/reading/letter_model.dart';
import 'package:larnes_mobile/trainers/shared/seeded_rng.dart';

/// Web: `platform/src/trainers/reading/letter-case-match/model.ts`

const minPairCount = 2;
const maxPairCount = 12;

class LetterMatchSideItem {
  const LetterMatchSideItem({
    required this.displayLetter,
    required this.id,
    required this.letter,
  });

  final String displayLetter;
  final String id;
  final String letter;
}

class LetterMatchRound {
  const LetterMatchRound({
    required this.leftItems,
    required this.rightItems,
  });

  final List<LetterMatchSideItem> leftItems;
  final List<LetterMatchSideItem> rightItems;
}

class LetterMatchConnection {
  const LetterMatchConnection({
    required this.leftId,
    required this.letter,
    required this.rightId,
  });

  final String leftId;
  final String letter;
  final String rightId;
}

bool canUsePairCount(List<String> practiceLetters, int pairCount) {
  return pairCount >= minPairCount &&
      pairCount <= maxPairCount &&
      practiceLetters.length >= pairCount;
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

List<String> pickLettersForRound({
  required int pairCount,
  required List<String> practiceLetters,
  required double Function() rng,
}) {
  if (practiceLetters.length < pairCount) {
    return [];
  }

  return _shuffleItems(practiceLetters, rng).take(pairCount).toList();
}

LetterMatchRound buildLetterMatchRound(
  List<String> selectedLetters,
  int seed,
) {
  final rng = createSeededRng(seed);

  final leftItems = [
    for (final letter in selectedLetters)
      LetterMatchSideItem(
        displayLetter: applyLetterCase(letter, 'lower'),
        id: 'left-$letter',
        letter: letter,
      ),
  ];

  final rightItems = [
    for (final letter in selectedLetters)
      LetterMatchSideItem(
        displayLetter: applyLetterCase(letter, 'upper'),
        id: 'right-$letter',
        letter: letter,
      ),
  ];

  return LetterMatchRound(
    leftItems: _shuffleItems(leftItems, rng),
    rightItems: _shuffleItems(
      rightItems,
      createSeededRng(seed + 19),
    ),
  );
}

int buildCaseMatchRoundSeed(List<Object> parts) {
  return hashParamsSeed([...parts, 'case-match']);
}

bool isCorrectLetterMatch(String leftLetter, String rightLetter) {
  return leftLetter == rightLetter;
}

bool isCaseMatchRoundComplete(
  List<LetterMatchConnection> connections,
  List<String> selectedLetters,
) {
  if (connections.length != selectedLetters.length) {
    return false;
  }

  final matched = connections.map((connection) => connection.letter).toSet();

  return selectedLetters.every(matched.contains);
}

List<String> buildSelectedLetters({
  required int pairCount,
  required List<String> practiceLetters,
  required int seed,
}) {
  final rng = createSeededRng(seed);

  return pickLettersForRound(
    pairCount: pairCount,
    practiceLetters: practiceLetters,
    rng: rng,
  );
}

List<String> parseCaseMatchPracticeLetters(String raw) =>
    parsePracticeLetters(raw);

String formatCaseMatchPracticeLetters(List<String> letters) =>
    formatPracticeLetters(letters);
