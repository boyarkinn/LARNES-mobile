import 'package:larnes_mobile/trainers/shared/trainer_constants.dart';

const distractorDigits = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];

class DigitToken {
  const DigitToken({
    required this.digit,
    required this.id,
    required this.isTarget,
  });

  final int digit;
  final String id;
  final bool isTarget;
}

class BuildDigitFieldInput {
  const BuildDigitFieldInput({
    required this.distractorCount,
    required this.rng,
    required this.targetCount,
    required this.targetDigit,
  });

  final int distractorCount;
  final double Function() rng;
  final int targetCount;
  final int targetDigit;
}

int normalizeTargetDigit(num value) {
  if (!value.isFinite) {
    return 0;
  }
  return value.truncate().clamp(0, 9);
}

bool canFitDigitField(int targetCount, int distractorCount) {
  return targetCount >= 1 &&
      distractorCount >= 0 &&
      targetCount + distractorCount <= maxDigitFieldTokens;
}

List<DigitToken> buildDigitTokens(BuildDigitFieldInput input) {
  final targetDigit = normalizeTargetDigit(input.targetDigit);
  final distractorPool =
      distractorDigits.where((digit) => digit != targetDigit).toList();

  final targets = List.generate(
    input.targetCount,
    (index) => DigitToken(
      digit: targetDigit,
      id: 'target-$index',
      isTarget: true,
    ),
  );

  final distractors = List.generate(input.distractorCount, (index) {
    final poolIndex = (input.rng() * distractorPool.length).floor();
    return DigitToken(
      digit: distractorPool[poolIndex.clamp(0, distractorPool.length - 1)],
      id: 'distractor-$index',
      isTarget: false,
    );
  });

  return _shuffleTokens([...targets, ...distractors], input.rng);
}

bool allTargetsFound(Set<String> foundTargetIds, List<DigitToken> tokens) {
  final targetIds =
      tokens.where((token) => token.isTarget).map((token) => token.id);

  final ids = targetIds.toList();
  return ids.isNotEmpty && ids.every(foundTargetIds.contains);
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
