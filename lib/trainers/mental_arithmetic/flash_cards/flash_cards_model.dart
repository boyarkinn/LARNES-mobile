// Web: `platform/src/trainers/mental-arithmetic/flash-cards/model.ts`

import 'dart:math' as math;

import 'package:larnes_mobile/trainers/mental_arithmetic/flashcard_digit_match/match_topic_values.dart';
import 'package:larnes_mobile/trainers/shared/param_coerce.dart';
import 'package:larnes_mobile/trainers/shared/seeded_rng.dart';
import 'package:larnes_mobile/trainers/shared/trainer_constants.dart';

const minFlashCardCount = 1;
const maxFlashCardCount = 10;
const defaultFlashCardCount = 5;

int _pow10(int exponent) {
  var result = 1;
  for (var index = 0; index < exponent; index += 1) {
    result *= 10;
  }
  return result;
}

int clampFlashCardCount(int cardCount) {
  return math.max(minFlashCardCount, math.min(maxFlashCardCount, cardCount));
}

int getFlashCardMaxValueForTopic(String topicId) {
  return buildMatchValuePools(topicId).maxValue;
}

int _distractorWindow(int digitCount) {
  if (digitCount <= 1) {
    return 4;
  }
  if (digitCount == 2) {
    return 8;
  }
  return 2 * _pow10(digitCount - 2);
}

List<T> _shuffled<T>(List<T> values, double Function() random) {
  final result = List<T>.from(values);
  for (var index = result.length - 1; index > 0; index -= 1) {
    final swapIndex = (random() * (index + 1)).floor().clamp(0, index);
    final temp = result[index];
    result[index] = result[swapIndex];
    result[swapIndex] = temp;
  }
  return result;
}

List<int> generateTopicFlashCardValues(
  int cardCount,
  String topicId,
  double Function() random,
) {
  final count = clampFlashCardCount(cardCount);
  final pools = buildMatchValuePools(topicId);
  final selected = <int>[];

  final focusShuffled = _shuffled(pools.focus, random);
  selected.add(focusShuffled.first);

  final preferred = [
    ..._shuffled(
      pools.prior.where((value) => !selected.contains(value)).toList(growable: false),
      random,
    ),
    ..._shuffled(
      pools.focus.where((value) => !selected.contains(value)).toList(growable: false),
      random,
    ),
  ];

  for (final value in preferred) {
    if (selected.length >= count) {
      break;
    }
    selected.add(value);
  }

  if (selected.length < count) {
    for (var value = 0; value <= pools.maxValue; value += 1) {
      if (!selected.contains(value)) {
        selected.add(value);
      }
      if (selected.length >= count) {
        break;
      }
    }
  }

  return _shuffled(selected.take(count).toList(growable: false), random);
}

int buildFlashCardSessionSeed({
  required int cardCount,
  required String topicId,
  int? snapshotSeed,
}) {
  return snapshotSeed ??
      hashParamsSeed([topicId, cardCount, 'flash-cards']);
}

List<int> buildFlashCardSessionValues({
  required int cardCount,
  required String topicId,
  String? values,
  required int masterSeed,
}) {
  if (values != null && values.trim().isNotEmpty) {
    final legacy = parseFlashCardValues(values);
    if (legacy.isNotEmpty) {
      return legacy;
    }
  }

  return generateTopicFlashCardValues(
    cardCount,
    topicId,
    createSeededRng(masterSeed),
  );
}

List<int> buildFlashCardAnswerOptions(int expected, {math.Random? random}) {
  final normalized = math.max(0, expected);
  final digitCount = normalized.toString().length;
  final lowerBound = digitCount == 1 ? 0 : _pow10(digitCount - 1);
  final upperBound = _pow10(digitCount) - 1;
  final window = _distractorWindow(digitCount);
  final candidates = <int>[];

  for (var distance = 1; distance <= window; distance += 1) {
    final lower = normalized - distance;
    final upper = normalized + distance;
    if (lower >= lowerBound) {
      candidates.add(lower);
    }
    if (upper <= upperBound) {
      candidates.add(upper);
    }
  }

  for (var distance = window + 1; candidates.length < 3; distance += 1) {
    final lower = normalized - distance;
    final upper = normalized + distance;
    if (lower >= lowerBound) {
      candidates.add(lower);
    }
    if (upper <= upperBound) {
      candidates.add(upper);
    }
  }

  final generator = random ?? math.Random();
  candidates.shuffle(generator);
  final options = <int>[normalized, ...candidates.take(3)];
  options.shuffle(generator);
  return options;
}

List<int> parseFlashCardValues(String raw) {
  return raw
      .split(RegExp(r'[,;]+'))
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .map((part) => int.tryParse(part))
      .whereType<int>()
      .where((value) => value >= 0)
      .toList(growable: false);
}

String formatFlashCardValues(List<int> values) {
  return values.join(',');
}

bool isValidFlashCardValuesForTopic(String raw, String topicId) {
  final values = parseFlashCardValues(raw);
  if (values.isEmpty) {
    return false;
  }

  final maxValue = getFlashCardMaxValueForTopic(topicId);
  return values.every((value) => value <= maxValue);
}

String normalizeFlashCardValuesInput(Object? values, int totalRods) {
  if (values is String && values.trim().isNotEmpty) {
    final parsed = parseFlashCardValues(values);
    if (parsed.isNotEmpty) {
      return formatFlashCardValues(parsed);
    }
  }

  if (values is num && values.isFinite) {
    return formatFlashCardValues([values.truncate().clamp(0, 1 << 31)]);
  }

  if (values is List) {
    final parsed = values
        .map((entry) => coerceInt(entry))
        .whereType<int>()
        .where((entry) => entry >= 0)
        .toList(growable: false);
    if (parsed.isNotEmpty) {
      return formatFlashCardValues(parsed);
    }
  }

  final legacyValue = coerceInt(values);
  if (legacyValue != null) {
    return formatFlashCardValues([legacyValue.clamp(0, 1 << 31)]);
  }

  return formatFlashCardValues([math.min(9, getMaxValueForRods(totalRods))]);
}

Map<String, dynamic> parseFlashCardParamsFromInput({
  Object? cardCount,
  Object? chainTopicId,
  Object? rounds,
  Object? topicId,
  Object? totalRods,
  Object? value,
  Object? values,
}) {
  final resolvedTopicId = resolveMatchTopicId(
    topicId ?? chainTopicId,
    totalRods,
  );
  final rods = resolveMatchTotalRods(resolvedTopicId);
  final legacyValuesRaw = values is String && values.trim().isNotEmpty
      ? values
      : value != null && value.toString().trim().isNotEmpty
      ? value.toString()
      : '';

  if (legacyValuesRaw.isNotEmpty) {
    final normalized = normalizeFlashCardValuesInput(legacyValuesRaw, rods);
    final parsed = parseFlashCardValues(normalized);

    return {
      'topicId': resolvedTopicId,
      'cardCount': clampFlashCardCount(
        parsed.isEmpty ? defaultFlashCardCount : parsed.length,
      ),
      'values': normalized,
    };
  }

  final resolvedCount = coerceInt(cardCount ?? rounds) ?? defaultFlashCardCount;

  return {
    'topicId': resolvedTopicId,
    'cardCount': clampFlashCardCount(resolvedCount),
  };
}
