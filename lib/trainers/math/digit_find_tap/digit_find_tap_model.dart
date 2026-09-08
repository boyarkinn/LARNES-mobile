import 'package:larnes_mobile/trainers/shared/trainer_constants.dart';

const distractorDigits = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
const digitFindTapTargetCount = 1;

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
    required this.targetDigit,
  });

  final int distractorCount;
  final double Function() rng;
  final int targetDigit;
}

int normalizeTargetDigit(num value) {
  if (!value.isFinite) {
    return 0;
  }
  return value.truncate().clamp(0, 9);
}

List<int> parseDigitFindTapValues(String raw) {
  return splitDigitFindTapValueParts(raw)
      .map((part) => int.tryParse(part))
      .whereType<int>()
      .where((value) => value >= 0 && value <= 9)
      .toList();
}

List<String> splitDigitFindTapValueParts(String raw) {
  return raw
      .split(RegExp(r'[,;]+'))
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList();
}

bool isValidDigitFindTapValuePart(String part) {
  if (!RegExp(r'^\d+$').hasMatch(part)) {
    return false;
  }

  final value = int.tryParse(part);
  return value != null && value >= 0 && value <= 9;
}

bool isValidDigitFindTapValues(String raw) {
  final parts = splitDigitFindTapValueParts(raw);
  return parts.isNotEmpty && parts.every(isValidDigitFindTapValuePart);
}

String formatDigitFindTapValues(List<int> values) {
  return values.join(',');
}

String normalizeDigitFindTapValuesInput(Object? values) {
  if (values is String && values.trim().isNotEmpty) {
    if (isValidDigitFindTapValues(values)) {
      return formatDigitFindTapValues(parseDigitFindTapValues(values));
    }
  }

  if (values is num && values.isFinite) {
    return formatDigitFindTapValues([normalizeTargetDigit(values)]);
  }

  if (values is List) {
    final parsed = values
        .map((entry) => entry is num ? normalizeTargetDigit(entry) : null)
        .whereType<int>()
        .toList();
    if (parsed.isNotEmpty) {
      return formatDigitFindTapValues(parsed);
    }
  }

  return '2,5,7';
}

bool canFitDigitField(int distractorCount) {
  return distractorCount >= 0 &&
      digitFindTapTargetCount + distractorCount <= maxDigitFieldTokens;
}

List<DigitToken> buildDigitTokens(BuildDigitFieldInput input) {
  final targetDigit = normalizeTargetDigit(input.targetDigit);
  final distractorPool =
      distractorDigits.where((digit) => digit != targetDigit).toList();

  final targets = [
    DigitToken(
      digit: targetDigit,
      id: 'target-0',
      isTarget: true,
    ),
  ];

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
