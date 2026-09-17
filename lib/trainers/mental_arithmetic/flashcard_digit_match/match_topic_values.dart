/// Пулы чисел для flashcard-digit-match по topicId (зеркало web).

import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/topic_rule.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/topics.dart';
import 'package:larnes_mobile/trainers/shared/trainer_constants.dart';

const defaultMatchTopicId = 'simple-1';

class MatchValuePools {
  const MatchValuePools({
    required this.focus,
    required this.maxValue,
    required this.prior,
    required this.totalRods,
  });

  final List<int> focus;
  final int maxValue;
  final List<int> prior;
  final int totalRods;
}

List<int> _uniqueSorted(Iterable<int> values) {
  final next = values.toSet().toList()..sort();
  return next;
}

bool _valueHasDigit(int value, int digit) {
  if (value == 0) {
    return digit == 0;
  }

  var current = value.abs();
  while (current > 0) {
    if (current % 10 == digit) {
      return true;
    }
    current ~/= 10;
  }
  return false;
}

List<int> _placeValuesForDigit(int digit, int totalRods) {
  final values = <int>[];
  var place = 1;
  for (var index = 0; index < totalRods; index++) {
    values.add(digit * place);
    place *= 10;
  }
  return values;
}

String legacyTotalRodsToTopicId(int totalRods) {
  final rods = totalRods < 1 ? 1 : totalRods;
  if (rods <= 1) {
    return 'simple-1';
  }
  if (rods == 2) {
    return 'simple-2digit';
  }
  return 'simple-3digit';
}

String resolveMatchTopicId(Object? topicIdRaw, [Object? legacyTotalRods]) {
  final topicText = topicIdRaw?.toString();
  if (topicText != null && isTopicId(topicText)) {
    return topicText;
  }

  if (legacyTotalRods != null && '$legacyTotalRods'.trim().isNotEmpty) {
    final parsed = num.tryParse('$legacyTotalRods');
    if (parsed != null) {
      return legacyTotalRodsToTopicId(parsed.truncate());
    }
  }

  return defaultMatchTopicId;
}

int resolveMatchTotalRods(String topicId) {
  return getTopicMeta(topicId).totalRods;
}

MatchValuePools buildMatchValuePools(String topicId) {
  final rule = getTopicRule(topicId);
  final totalRods = rule.totalRods;
  final maxValue = getMaxValueForRods(totalRods);
  final candidatePool = _uniqueSorted([
    0,
    ...rule.candidateAmounts,
  ].where((value) => value >= 0 && value <= maxValue));

  var focus = <int>[];
  final focusAmounts = rule.focusAmounts;
  final focusTechniqueN = rule.focusTechniqueN;

  if (focusAmounts != null && focusAmounts.isNotEmpty) {
    focus = _uniqueSorted(
      focusAmounts.where((value) => value >= 0 && value <= maxValue),
    );
  } else if (focusTechniqueN != null) {
    focus = _uniqueSorted([
      ..._placeValuesForDigit(focusTechniqueN, totalRods)
          .where((value) => value <= maxValue),
      ...candidatePool.where((value) => _valueHasDigit(value, focusTechniqueN)),
    ]);
  } else {
    focus = candidatePool.isNotEmpty
        ? candidatePool
        : [maxValue < 1 ? 0 : 1];
  }

  if (focus.isEmpty) {
    focus = candidatePool.isNotEmpty
        ? [candidatePool.last]
        : [maxValue < 1 ? 0 : 1];
  }

  var prior =
      candidatePool.where((value) => !focus.contains(value)).toList();
  if (prior.isEmpty) {
    prior = [
      for (var value = 0; value <= maxValue; value++)
        if (!focus.contains(value)) value,
    ];
  }

  return MatchValuePools(
    focus: focus,
    maxValue: maxValue,
    prior: prior,
    totalRods: totalRods,
  );
}
