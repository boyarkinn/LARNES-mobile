import 'dart:math' as math;

import 'package:larnes_mobile/trainers/mental_arithmetic/flashcard_digit_match/match_colors.dart';
import 'package:larnes_mobile/trainers/shared/seeded_rng.dart';
import 'package:larnes_mobile/trainers/shared/trainer_constants.dart';

export 'package:larnes_mobile/trainers/shared/trainer_constants.dart'
    show maxMatchPairs, minMatchPairs;

const minMatchRounds = 1;
const maxMatchRounds = 10;

enum FlashcardTargetMode { digits, dots }

FlashcardTargetMode normalizeTargetMode(Object? value) {
  return value == 'dots'
      ? FlashcardTargetMode.dots
      : FlashcardTargetMode.digits;
}

class MatchItem {
  const MatchItem({
    required this.id,
    required this.value,
    required this.leftDisplayColor,
    required this.rightDisplayColor,
  });

  final String id;
  final int value;
  final int leftDisplayColor;
  final int rightDisplayColor;
}

class MatchRound {
  const MatchRound({
    required this.leftItems,
    required this.rightItems,
    required this.values,
  });

  final List<MatchItem> leftItems;
  final List<MatchItem> rightItems;
  final List<int> values;
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

int clampPairCount(int pairCount) {
  return math.max(minMatchPairs, math.min(maxMatchPairs, pairCount));
}

int clampRounds(int rounds) {
  return math.max(minMatchRounds, math.min(maxMatchRounds, rounds));
}

List<int> generateRandomValues(
  int pairCount,
  int totalRods,
  double Function() rng,
) {
  final maxValue = getMaxValueForRods(totalRods);
  final pool = List<int>.generate(maxValue + 1, (index) => index);

  return _shuffleItems(
    pool,
    rng,
  ).take(clampPairCount(pairCount)).toList(growable: false);
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

MatchRound buildMatchRound(
  List<int> values,
  int seed,
  List<MatchColorPair> colorPairs,
) {
  final rng = createSeededRng(seed);
  final items = values
      .asMap()
      .entries
      .map((entry) {
        final pair = colorPairs[entry.key];

        return MatchItem(
          id: 'pair-${entry.key}',
          value: entry.value,
          leftDisplayColor: pair.left,
          rightDisplayColor: pair.right,
        );
      })
      .toList(growable: false);

  return MatchRound(
    leftItems: _shuffleItems(items, rng),
    rightItems: _shuffleItems(items, rng),
    values: values,
  );
}

int buildRoundSeed(int masterSeed, int roundIndex) {
  return hashParamsSeed([masterSeed, roundIndex, 'flashcard-match-round']);
}

List<MatchRound> buildFlashcardMatchPlan({
  required int pairCount,
  required int rounds,
  required int totalRods,
  required int masterSeed,
}) {
  final safePairCount = clampPairCount(pairCount);
  final safeRounds = clampRounds(rounds);
  final plan = <MatchRound>[];

  for (var roundIndex = 0; roundIndex < safeRounds; roundIndex++) {
    final roundSeed = buildRoundSeed(masterSeed, roundIndex);
    final colorSeed = buildMatchColorSeed(masterSeed, roundIndex);
    final values = generateRandomValues(
      safePairCount,
      totalRods,
      createSeededRng(roundSeed),
    );
    final colorPairs = colorPairsForRound(safePairCount, colorSeed);

    plan.add(buildMatchRound(values, roundSeed, colorPairs));
  }

  return plan;
}

bool isCorrectConnection(int leftValue, int rightValue) {
  return leftValue == rightValue;
}

bool isRoundComplete(List<MatchConnection> connections, int pairCount) {
  if (connections.length != pairCount) {
    return false;
  }

  final leftIds = <String>{};
  final rightIds = <String>{};

  for (final connection in connections) {
    if (leftIds.contains(connection.leftId) ||
        rightIds.contains(connection.rightId)) {
      return false;
    }

    leftIds.add(connection.leftId);
    rightIds.add(connection.rightId);
  }

  return true;
}

Map<String, dynamic> parseFlashcardMatchParamsFromInput({
  Object? pairCount,
  Object? rounds,
  Object? targetMode,
  Object? totalRods,
}) {
  return {
    'pairCount': clampPairCount(
      (num.tryParse('$pairCount') ?? minMatchPairs).truncate(),
    ),
    'rounds': clampRounds(
      (num.tryParse('$rounds') ?? minMatchRounds).truncate(),
    ),
    'targetMode': normalizeTargetMode(targetMode) == FlashcardTargetMode.dots
        ? 'dots'
        : 'digits',
    'totalRods': math.max(1, (num.tryParse('$totalRods') ?? 1).truncate()),
  };
}
