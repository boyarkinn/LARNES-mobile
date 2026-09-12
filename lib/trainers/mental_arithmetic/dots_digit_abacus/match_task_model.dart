// Модель части 2: точки → цифра → абакус (3 колонки, отвлекающие).
// Web: `platform/src/trainers/mental-arithmetic/dots-digit-abacus/match-task-model.ts`

import 'package:larnes_mobile/trainers/mental_arithmetic/flashcard_digit_match/match_colors.dart';
import 'package:larnes_mobile/trainers/shared/seeded_rng.dart';

const matchTaskOptionCount = 3;
const matchTaskDistractorCount = 2;
const dotsSourceId = 'dots-source';

enum MatchTaskConnectionKind { dotsDigit, digitAbacus }

class MatchTaskItem {
  const MatchTaskItem({
    required this.displayColor,
    required this.id,
    required this.isTarget,
    required this.value,
  });

  final int displayColor;
  final String id;
  final bool isTarget;
  final int value;
}

class MatchTaskPlan {
  const MatchTaskPlan({
    required this.abacusItems,
    required this.digitItems,
    required this.dotsValue,
    required this.targetAbacusId,
    required this.targetDigitId,
    required this.targetValue,
  });

  final List<MatchTaskItem> abacusItems;
  final List<MatchTaskItem> digitItems;
  final int dotsValue;
  final String targetAbacusId;
  final String targetDigitId;
  final int targetValue;
}

class MatchTaskConnection {
  const MatchTaskConnection({
    required this.fromId,
    required this.kind,
    required this.toId,
    required this.value,
  });

  final String fromId;
  final MatchTaskConnectionKind kind;
  final String toId;
  final int value;
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

List<int> _pickDistractorValues(
  int targetValue,
  int count,
  double Function() rng,
) {
  final pool = List<int>.generate(
    10,
    (digit) => digit,
  ).where((digit) => digit != targetValue).toList();
  return _shuffleItems(pool, rng).take(count).toList(growable: false);
}

List<MatchTaskItem> _buildItems(
  String prefix,
  List<int> values,
  int targetValue,
  List<int> colors,
) {
  return values
      .asMap()
      .entries
      .map(
        (entry) => MatchTaskItem(
          displayColor: colors[entry.key],
          id: '$prefix-${entry.value}-${entry.key}',
          isTarget: entry.value == targetValue,
          value: entry.value,
        ),
      )
      .toList(growable: false);
}

int buildMatchTaskSeed(int value, [int? masterSeed]) {
  return hashParamsSeed([
    masterSeed ?? value,
    value,
    'dots-digit-abacus-match-task',
  ]);
}

MatchTaskPlan buildMatchTaskPlan(int value, [int? seed]) {
  final targetValue = value.clamp(0, 9);
  final rng = createSeededRng(buildMatchTaskSeed(targetValue, seed));
  final digitValues = _shuffleItems([
    targetValue,
    ..._pickDistractorValues(targetValue, matchTaskDistractorCount, rng),
  ], rng);
  final abacusValues = _shuffleItems([
    targetValue,
    ..._pickDistractorValues(targetValue, matchTaskDistractorCount, rng),
  ], rng);
  final digitColors = pickUniqueMatchColors(matchTaskOptionCount, rng);
  final abacusColors = pickUniqueMatchColors(matchTaskOptionCount, rng);

  final digitItems = _buildItems(
    'digit',
    digitValues,
    targetValue,
    digitColors,
  );
  final abacusItems = _buildItems(
    'abacus',
    abacusValues,
    targetValue,
    abacusColors,
  );

  return MatchTaskPlan(
    abacusItems: abacusItems,
    digitItems: digitItems,
    dotsValue: targetValue,
    targetAbacusId: abacusItems.firstWhere((item) => item.isTarget).id,
    targetDigitId: digitItems.firstWhere((item) => item.isTarget).id,
    targetValue: targetValue,
  );
}

bool isMatchTaskComplete(List<MatchTaskConnection> connections) {
  return connections.any(
        (connection) => connection.kind == MatchTaskConnectionKind.dotsDigit,
      ) &&
      connections.any(
        (connection) => connection.kind == MatchTaskConnectionKind.digitAbacus,
      );
}

enum MatchTaskStep { dotsToDigit, digitToAbacus, complete }

MatchTaskStep getMatchTaskStep(List<MatchTaskConnection> connections) {
  if (connections.any(
    (connection) => connection.kind == MatchTaskConnectionKind.digitAbacus,
  )) {
    return MatchTaskStep.complete;
  }

  if (connections.any(
    (connection) => connection.kind == MatchTaskConnectionKind.dotsDigit,
  )) {
    return MatchTaskStep.digitToAbacus;
  }

  return MatchTaskStep.dotsToDigit;
}
