import 'dart:math' as math;

import 'package:larnes_mobile/trainers/shared/seeded_rng.dart';
import 'package:larnes_mobile/trainers/shared/trainer_constants.dart';

export 'package:larnes_mobile/trainers/shared/trainer_constants.dart'
    show areFlashcardValuesValid, maxMatchPairs, minMatchPairs;

class MatchItem {
  const MatchItem({required this.id, required this.value});

  final String id;
  final int value;
}

class MatchRound {
  const MatchRound({
    required this.leftItems,
    required this.rightItems,
  });

  final List<MatchItem> leftItems;
  final List<MatchItem> rightItems;
}

class MatchConnection {
  const MatchConnection({
    required this.leftId,
    required this.rightId,
    required this.value,
  });

  final String leftId;
  final String rightId;
  final int value;
}

List<int> normalizeValues(List<int> values) {
  return values.map((value) => math.max(0, value.truncate())).toList();
}

bool areValuesValid(List<int> values, int totalRods) {
  return areFlashcardValuesValid(values, totalRods);
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

MatchRound buildMatchRound(List<int> values, int seed) {
  final rng = createSeededRng(seed);
  final items = values
      .asMap()
      .entries
      .map((entry) => MatchItem(id: 'pair-${entry.key}', value: entry.value))
      .toList();

  return MatchRound(
    leftItems: _shuffleItems(items, rng),
    rightItems: _shuffleItems(items, rng),
  );
}

bool isCorrectConnection(int leftValue, int rightValue) {
  return leftValue == rightValue;
}

bool isRoundComplete(List<MatchConnection> connections, List<int> values) {
  if (connections.length != values.length) {
    return false;
  }

  final matchedValues = connections.map((connection) => connection.value).toSet();

  return values.every(matchedValues.contains);
}

List<int> parseMatchValuesFromInput({
  Object? pairCount,
  Object? value0,
  Object? value1,
  Object? value2,
  Object? value3,
}) {
  final count = math.max(
    minMatchPairs,
    math.min(maxMatchPairs, (num.tryParse('$pairCount') ?? minMatchPairs).truncate()),
  );
  final rawValues = [value0, value1, value2, value3];

  return normalizeValues(
    List.generate(count, (index) {
      final parsed = num.tryParse('${rawValues[index]}');
      return parsed?.isFinite == true ? parsed!.truncate() : index;
    }),
  );
}
