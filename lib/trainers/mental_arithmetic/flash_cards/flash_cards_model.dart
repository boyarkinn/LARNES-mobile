/// Web: `platform/src/trainers/mental-arithmetic/flash-cards/model.ts`

import 'dart:math' as math;

import 'package:larnes_mobile/trainers/shared/param_coerce.dart';
import 'package:larnes_mobile/trainers/shared/trainer_constants.dart';

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

bool isValidFlashCardValues(String raw, int totalRods) {
  final values = parseFlashCardValues(raw);
  if (values.isEmpty) {
    return false;
  }

  final maxValue = getMaxValueForRods(totalRods);
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

  return formatFlashCardValues([
    math.min(9, getMaxValueForRods(totalRods)),
  ]);
}

Map<String, dynamic> parseFlashCardParamsFromInput({
  Object? totalRods,
  Object? value,
  Object? values,
}) {
  final rods = coerceInt(totalRods);
  final resolvedRods = rods != null && rods > 0 ? rods : 1;
  final valuesRaw = values is String && values.trim().isNotEmpty
      ? values
      : value != null && value.toString().trim().isNotEmpty
          ? value.toString()
          : '3,7,15';

  return {
    'totalRods': resolvedRods,
    'values': normalizeFlashCardValuesInput(valuesRaw, resolvedRods),
  };
}
