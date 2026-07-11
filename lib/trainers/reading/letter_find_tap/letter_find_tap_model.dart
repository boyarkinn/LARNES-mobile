import 'package:larnes_mobile/trainers/reading/letter_model.dart';

/// Web: `platform/src/trainers/reading/letter-find-tap/model.ts`

class LetterToken {
  const LetterToken({
    required this.letter,
    required this.id,
    required this.isTarget,
    this.displayColor,
  });

  final String letter;
  final String id;
  final bool isTarget;
  final String? displayColor;
}

class BuildLetterFieldInput {
  const BuildLetterFieldInput({
    required this.distractorCount,
    required this.letterCase,
    required this.rng,
    required this.targetCount,
    required this.targetLetter,
  });

  final int distractorCount;
  final String letterCase;
  final double Function() rng;
  final int targetCount;
  final String targetLetter;
}

List<LetterToken> buildLetterTokens(BuildLetterFieldInput input) {
  final targetLetter = normalizeTargetLetter(input.targetLetter);
  final displayTarget = applyLetterCase(targetLetter, input.letterCase);
  final distractorPool = russianLettersUpper
      .where((letter) => letter != targetLetter)
      .map((letter) => applyLetterCase(letter, input.letterCase))
      .toList();

  final targets = List.generate(
    input.targetCount,
    (index) => LetterToken(
      letter: displayTarget,
      id: 'target-$index',
      isTarget: true,
    ),
  );

  final distractors = List.generate(input.distractorCount, (index) {
    final poolIndex = (input.rng() * distractorPool.length).floor();
    return LetterToken(
      letter: distractorPool[poolIndex.clamp(0, distractorPool.length - 1)],
      id: 'distractor-$index',
      isTarget: false,
    );
  });

  return _shuffleTokens([...targets, ...distractors], input.rng);
}

bool allTargetsFound(Set<String> foundTargetIds, List<LetterToken> tokens) {
  final targetIds =
      tokens.where((token) => token.isTarget).map((token) => token.id).toList();

  return targetIds.isNotEmpty &&
      targetIds.every(foundTargetIds.contains);
}

List<T> _shuffleTokens<T>(List<T> items, double Function() rng) {
  final next = List<T>.from(items);

  for (var index = next.length - 1; index > 0; index--) {
    final swapIndex = (rng() * (index + 1)).floor();
    final temp = next[index];
    next[index] = next[swapIndex];
    next[swapIndex] = temp;
  }

  return next;
}
