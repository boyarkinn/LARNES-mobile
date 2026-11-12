import 'package:larnes_mobile/trainers/catalog/validate_trainer_params_result.dart';
import 'package:larnes_mobile/trainers/intel/fly_track/definition.dart';
import 'package:larnes_mobile/trainers/math/apple_count_show/apple_count_show_model.dart';
import 'package:larnes_mobile/trainers/math/digit_find_tap/digit_find_tap_model.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/topics.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/types.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/flash_cards/flash_cards_model.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/dots_digit_abacus/dots_digit_abacus_model.dart'
    hide getMaxValueForRods;
import 'package:larnes_mobile/trainers/mental_arithmetic/flashcard_digit_match/flashcard_digit_match_model.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/flashcard_digit_match/match_topic_values.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/static_example_show/example_logic.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/example_parser.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/abacus_movement_plan.dart';
import 'package:larnes_mobile/trainers/shared/param_coerce.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/abacus_warmup_topics.dart' as warmup;
import 'package:larnes_mobile/trainers/shared/trainer_constants.dart';

ValidateTrainerParamsResult _fail(String message) {
  return ValidateTrainerParamsResult.failure(message);
}

ValidateTrainerParamsResult validateAbacusTopicExplanationParams(
  Map<String, dynamic> raw,
) {
  final lessonId = raw['lessonId'] ?? 'simple-1';
  final speed = raw['speed'] ?? 'medium';
  const allowedLessons = {
    'simple-1', 'simple-2', 'simple-3', 'simple-4', 'simple-5',
    'simple-6', 'simple-7', 'simple-8', 'simple-9',
    'simple-tens', 'simple-11-19',
    'simple-44', 'simple-55', 'simple-66', 'simple-77', 'simple-88', 'simple-99',
    'simple-hundreds', 'simple-000',
    'brother-4', 'brother-3', 'brother-2', 'brother-1',
    'friend-9', 'friend-8', 'friend-7', 'friend-6', 'friend-5',
    'friend-4', 'friend-3', 'friend-2', 'friend-1',
    'friend-brother-6', 'friend-brother-7',
    'friend-brother-8', 'friend-brother-9',
  };
  if (lessonId is! String || !allowedLessons.contains(lessonId) ||
      speed is! String ||
      !const {'slow', 'medium', 'fast'}.contains(speed)) {
    return _fail('Некорректные параметры объяснения темы.');
  }
  return ValidateTrainerParamsResult.success({
    'lessonId': lessonId,
    'speed': speed,
  });
}

ValidateTrainerParamsResult validateAbacusWarmupParams(Map<String, dynamic> raw) {
  final warmupType = raw['warmupType'] ?? 'simple-9';
  final speed = raw['speed'] ?? 'medium';
  final withExplanations = raw['withExplanations'] ?? true;
  final selected = raw['warmupTopics'];
  const allowedTypes = {
    'simple-9', 'simple-tens', 'simple-2digit', 'brothers', 'friends',
  };
  const allowedSpeeds = {'slow', 'medium', 'fast'};

  if (warmupType is! String || !allowedTypes.contains(warmupType) ||
      speed is! String || !allowedSpeeds.contains(speed) || withExplanations is! bool) {
    return _fail('Некорректные параметры разминки.');
  }
  List<dynamic>? normalized;
  if (selected != null) {
    if (selected is! List || selected.isEmpty || selected.length > 40) {
      return _fail('Выберите хотя бы одну тему разминки.');
    }
    try {
      if (selected.every((value) => value is int)) {
        if (selected.length > 9) return _fail('Некорректные темы разминки.');
        normalized = warmup.resolveWarmupTopics(warmupType, selected.cast<int>());
      } else {
        normalized = warmup.resolveWarmupSelection(warmupType, selected);
      }
    } on ArgumentError {
      return _fail('Неизвестная тема разминки.');
    }
  }

  final narrated = raw['warmupNarratedTopics'];
  List<String>? normalizedNarration;
  if (narrated != null) {
    if (narrated is! List || narrated.length > 40 || narrated.any((id) => id is! String)) {
      return _fail('Некорректная настройка озвучки тем.');
    }
    try {
      normalizedNarration = warmup.resolveWarmupNarratedTopics(
        warmup.resolveWarmupSelection(warmupType, normalized), narrated.cast<String>());
    } on ArgumentError { return _fail('Озвучка доступна только для выбранных тем.'); }
  }
  return ValidateTrainerParamsResult.success({
    'warmupType': warmupType,
    'speed': speed,
    'withExplanations': withExplanations,
    if (normalized != null) 'warmupTopics': normalized,
    if (normalizedNarration != null) 'warmupNarratedTopics': normalizedNarration,
  });
}

ValidateTrainerParamsResult validateNumberRowShowParams(Map<String, dynamic> raw) {
  final digit = coerceInt(raw['digit']);
  if (digit == null || digit < 1 || digit > 9) {
    return _fail('╨Э╨╡╨║╨╛╤А╤А╨╡╨║╤В╨╜╤Л╨╡ ╨┐╨░╤А╨░╨╝╨╡╤В╤А╤Л.');
  }

  final stepPauseSecRaw = raw['stepPauseSec'];
  final double stepPauseSec;
  if (stepPauseSecRaw == null) {
    stepPauseSec = 1;
  } else {
    final parsed = stepPauseSecRaw is num
        ? stepPauseSecRaw.toDouble()
        : double.tryParse('$stepPauseSecRaw');
    if (parsed == null || parsed < 0.5 || parsed > 3) {
      return _fail('╨Э╨╡╨║╨╛╤А╤А╨╡╨║╤В╨╜╤Л╨╡ ╨┐╨░╤А╨░╨╝╨╡╤В╤А╤Л.');
    }
    stepPauseSec = parsed;
  }

  return ValidateTrainerParamsResult.success({
    'digit': digit,
    'stepPauseSec': stepPauseSec,
  });
}

ValidateTrainerParamsResult validateAppleCountShowParams(Map<String, dynamic> raw) {
  final targetCount = coerceInt(raw['targetCount'] ?? raw['digit']);
  if (targetCount == null || targetCount < 1 || targetCount > 9) {
    return _fail('╨Э╨╡╨║╨╛╤А╤А╨╡╨║╤В╨╜╤Л╨╡ ╨┐╨░╤А╨░╨╝╨╡╤В╤А╤Л.');
  }

  final totalApples = coerceInt(raw['totalApples'] ?? raw['totalFruits']);
  final resolvedTotalApples = totalApples ?? (targetCount + 2).clamp(1, 15);
  if (resolvedTotalApples < 1 || resolvedTotalApples > 15) {
    return _fail('╨Э╨╡╨║╨╛╤А╤А╨╡╨║╤В╨╜╤Л╨╡ ╨┐╨░╤А╨░╨╝╨╡╤В╤А╤Л.');
  }
  if (resolvedTotalApples < targetCount) {
    return _fail('╨Э╨╡╨║╨╛╤А╤А╨╡╨║╤В╨╜╤Л╨╡ ╨┐╨░╤А╨░╨╝╨╡╤В╤А╤Л.');
  }

  final targetDisplay = normalizeTargetDisplay(raw['targetDisplay'] ?? raw['targetMode']);

  return ValidateTrainerParamsResult.success({
    'targetCount': targetCount,
    'totalApples': resolvedTotalApples,
    'targetDisplay': targetDisplay,
  });
}

ValidateTrainerParamsResult validateFlashCardsParams(Map<String, dynamic> raw) {
  final topicId = resolveMatchTopicId(
    raw['topicId'] ?? raw['chainTopicId'],
    raw['totalRods'],
  );
  final totalRods = resolveMatchTotalRods(topicId);
  final valuesRaw = raw['values'];
  final hasLegacyValues = valuesRaw is String && valuesRaw.trim().isNotEmpty ||
      raw['value'] != null;

  if (hasLegacyValues) {
    final valuesString = valuesRaw is String && valuesRaw.trim().isNotEmpty
        ? normalizeFlashCardValuesInput(valuesRaw, totalRods)
        : normalizeFlashCardValuesInput(raw['value'], totalRods);

    if (!isValidFlashCardValuesForTopic(valuesString, topicId)) {
      final maxValue = getFlashCardMaxValueForTopic(topicId);
      return _fail('Числа вне диапазона темы (0…$maxValue).');
    }

    final parsed = parseFlashCardValues(valuesString);

    return ValidateTrainerParamsResult.success({
      'topicId': topicId,
      'cardCount': clampFlashCardCount(parsed.length),
      'values': formatFlashCardValues(parsed),
    });
  }

  final cardCount = clampFlashCardCount(
    coerceInt(raw['cardCount'] ?? raw['rounds']) ?? defaultFlashCardCount,
  );

  return ValidateTrainerParamsResult.success({
    'topicId': topicId,
    'cardCount': cardCount,
  });
}

ValidateTrainerParamsResult validateDotsDigitAbacusParams(Map<String, dynamic> raw) {
  final value = coerceInt(raw['value']);
  if (value == null || value < 0 || value > kDotsDigitAbacusMaxValue) {
    return _fail('╨Э╨╡╨║╨╛╤А╤А╨╡╨║╤В╨╜╤Л╨╡ ╨┐╨░╤А╨░╨╝╨╡╤В╤А╤Л.');
  }

  return ValidateTrainerParamsResult.success({
    'totalRods': kDotsDigitAbacusTotalRods,
    'value': value,
  });
}

ValidateTrainerParamsResult validateStaticExampleShowParams(Map<String, dynamic> raw) {
  final operation = raw['operation'];
  final operandA = coerceInt(raw['operandA']);
  final operandB = coerceInt(raw['operandB']);
  final totalRods = coerceInt(raw['totalRods']);

  if (operation is! String || !isStaticExampleOperation(operation)) {
    return _fail('╨Э╨╡╨║╨╛╤А╤А╨╡╨║╤В╨╜╤Л╨╡ ╨┐╨░╤А╨░╨╝╨╡╤В╤А╤Л.');
  }
  if (operandA == null || operandA < 0 || operandA > 99) {
    return _fail('╨Э╨╡╨║╨╛╤А╤А╨╡╨║╤В╨╜╤Л╨╡ ╨┐╨░╤А╨░╨╝╨╡╤В╤А╤Л.');
  }
  if (operandB == null || operandB < 0 || operandB > 99) {
    return _fail('╨Э╨╡╨║╨╛╤А╤А╨╡╨║╤В╨╜╤Л╨╡ ╨┐╨░╤А╨░╨╝╨╡╤В╤А╤Л.');
  }
  if (totalRods == null || totalRods < 1 || totalRods > 2) {
    return _fail('╨Э╨╡╨║╨╛╤А╤А╨╡╨║╤В╨╜╤Л╨╡ ╨┐╨░╤А╨░╨╝╨╡╤В╤А╤Л.');
  }

  final maxValue = maxValueForRods(totalRods);

  if (operandA > maxValue) {
    return _fail(
      '╨Я╨╡╤А╨▓╨╛╨╡ ╤З╨╕╤Б╨╗╨╛ ╨╜╨╡ ╨┐╨╛╨╝╨╡╤Й╨░╨╡╤В╤Б╤П ╨▓ $totalRods ╤А╨░╨╖╤А╤П╨┤(╨╛╨▓) (╨╝╨░╨║╤Б. $maxValue)',
    );
  }

  if (operation == 'subtract' && operandA < operandB) {
    return _fail('╨Я╤А╨╕ ╨▓╤Л╤З╨╕╤В╨░╨╜╨╕╨╕ ╨┐╨╡╤А╨▓╨╛╨╡ ╤З╨╕╤Б╨╗╨╛ ╨╜╨╡ ╨╝╨╛╨╢╨╡╤В ╨▒╤Л╤В╤М ╨╝╨╡╨╜╤М╤И╨╡ ╨▓╤В╨╛╤А╨╛╨│╨╛.');
  }

  final values = resolveStaticExampleAbacusValues(
    operation: operation,
    operandA: operandA,
    operandB: operandB,
  );

  if (values.rightValue < 0) {
    return _fail('╨Ю╤В╨▓╨╡╤В ╨╜╨╡ ╨╝╨╛╨╢╨╡╤В ╨▒╤Л╤В╤М ╨╛╤В╤А╨╕╤Ж╨░╤В╨╡╨╗╤М╨╜╤Л╨╝.');
  }

  if (values.rightValue > maxValue) {
    return _fail(
      '╨Ю╤В╨▓╨╡╤В ╨╜╨╡ ╨┐╨╛╨╝╨╡╤Й╨░╨╡╤В╤Б╤П ╨▓ $totalRods ╤А╨░╨╖╤А╤П╨┤(╨╛╨▓) (╨╝╨░╨║╤Б. $maxValue)',
    );
  }

  if (values.leftValue > maxValue) {
    return _fail(
      '╨Ы╨╡╨▓╤Л╨╣ ╨░╨▒╨░╨║╤Г╤Б ╨╜╨╡ ╨┐╨╛╨╝╨╡╤Й╨░╨╡╤В╤Б╤П ╨▓ $totalRods ╤А╨░╨╖╤А╤П╨┤(╨╛╨▓) (╨╝╨░╨║╤Б. $maxValue)',
    );
  }

  return ValidateTrainerParamsResult.success({
    'operation': operation,
    'operandA': operandA,
    'operandB': operandB,
    'totalRods': totalRods,
  });
}

ValidateTrainerParamsResult validateExampleVisualizationParams(
  Map<String, dynamic> raw,
) {
  final example = raw['example'];
  final stepPauseSec = coerceDouble(raw['stepPauseSec']);
  final totalRods = coerceInt(raw['totalRods']);

  if (example is! String || example.trim().isEmpty) {
    return _fail('╨Э╨╡╨║╨╛╤А╤А╨╡╨║╤В╨╜╤Л╨╡ ╨┐╨░╤А╨░╨╝╨╡╤В╤А╤Л.');
  }
  if (stepPauseSec == null || stepPauseSec < 0.5 || stepPauseSec > 30) {
    return _fail('╨Э╨╡╨║╨╛╤А╤А╨╡╨║╤В╨╜╤Л╨╡ ╨┐╨░╤А╨░╨╝╨╡╤В╤А╤Л.');
  }
  if (totalRods == null || totalRods < 1 || totalRods > 2) {
    return _fail('╨Э╨╡╨║╨╛╤А╤А╨╡╨║╤В╨╜╤Л╨╡ ╨┐╨░╤А╨░╨╝╨╡╤В╤А╤Л.');
  }

  final trimmedExample = example.trim();
  late final List<ExampleAction> actions;

  try {
    actions = parseExampleActions(trimmedExample);
  } on FormatException catch (error) {
    return _fail(error.message);
  } catch (_) {
    return _fail('╨Э╨╡╨▓╨╡╤А╨╜╤Л╨╣ ╤Д╨╛╤А╨╝╨░╤В ╨┐╤А╨╕╨╝╨╡╤А╨░.');
  }

  final normalizedExample = formatExample(actions);

  final stateError = validateExampleForRods(normalizedExample, totalRods);
  if (stateError != null) {
    return _fail(stateError);
  }
  try {
    planAbacusMovements(normalizedExample, totalRods);
  } catch (_) {
    return _fail('Неверный пример.');
  }

  return ValidateTrainerParamsResult.success({
    'example': normalizedExample,
    'stepPauseSec': stepPauseSec,
    'totalRods': totalRods,
  });
}

ValidateTrainerParamsResult validateDigitFindTapParams(Map<String, dynamic> raw) {
  final distractorCount = coerceInt(raw['distractorCount']);
  if (distractorCount == null || distractorCount < 0 || distractorCount > 30) {
    return _fail('╨Э╨╡╨║╨╛╤А╤А╨╡╨║╤В╨╜╤Л╨╡ ╨┐╨░╤А╨░╨╝╨╡╤В╤А╤Л.');
  }

  final valuesRaw = raw['values'] ?? raw['digit'];
  final String valuesString;
  if (valuesRaw is String && valuesRaw.trim().isNotEmpty) {
    valuesString = valuesRaw.trim();
  } else if (valuesRaw is num && valuesRaw.isFinite) {
    valuesString = normalizeTargetDigit(valuesRaw).toString();
  } else {
    return _fail('╨г╨║╨░╨╢╨╕╤В╨╡ ╤Ж╨╕╤Д╤А╤Л ╨╛╤В 0 ╨┤╨╛ 9 ╤З╨╡╤А╨╡╨╖ ╨╖╨░╨┐╤П╤В╤Г╤О.');
  }

  if (!isValidDigitFindTapValues(valuesString)) {
    return _fail('╨г╨║╨░╨╢╨╕╤В╨╡ ╤Ж╨╕╤Д╤А╤Л ╨╛╤В 0 ╨┤╨╛ 9 ╤З╨╡╤А╨╡╨╖ ╨╖╨░╨┐╤П╤В╤Г╤О.');
  }

  if (!canFitDigitField(distractorCount)) {
    return _fail('╨б╨╗╨╕╤И╨║╨╛╨╝ ╨╝╨╜╨╛╨│╨╛ ╤Ж╨╕╤Д╤А ╨╜╨░ ╤Н╨║╤А╨░╨╜╨╡ (╨╝╨░╨║╤Б╨╕╨╝╤Г╨╝ $maxDigitFieldTokens).');
  }

  return ValidateTrainerParamsResult.success({
    'distractorCount': distractorCount,
    'values': formatDigitFindTapValues(parseDigitFindTapValues(valuesString)),
  });
}

ValidateTrainerParamsResult validateFruitCountTapParams(Map<String, dynamic> raw) {
  final answerRangeStart = coerceInt(raw['answerRangeStart']);
  final fruitTypeCount = coerceInt(raw['fruitTypeCount']);
  final targetCount = coerceInt(raw['targetCount']);
  final totalFruits = coerceInt(raw['totalFruits']);
  final targetFruit = raw['targetFruit'];

  if (answerRangeStart == null || answerRangeStart < 0 || answerRangeStart > 6) {
    return _fail('╨Э╨╡╨║╨╛╤А╤А╨╡╨║╤В╨╜╤Л╨╡ ╨┐╨░╤А╨░╨╝╨╡╤В╤А╤Л.');
  }
  if (fruitTypeCount == null || fruitTypeCount < 1 || fruitTypeCount > 10) {
    return _fail('╨Э╨╡╨║╨╛╤А╤А╨╡╨║╤В╨╜╤Л╨╡ ╨┐╨░╤А╨░╨╝╨╡╤В╤А╤Л.');
  }
  if (targetCount == null || targetCount < 0 || targetCount > 9) {
    return _fail('╨Э╨╡╨║╨╛╤А╤А╨╡╨║╤В╨╜╤Л╨╡ ╨┐╨░╤А╨░╨╝╨╡╤В╤А╤Л.');
  }
  if (totalFruits == null || totalFruits < 1 || totalFruits > maxFruitFieldTokens) {
    return _fail('╨Э╨╡╨║╨╛╤А╤А╨╡╨║╤В╨╜╤Л╨╡ ╨┐╨░╤А╨░╨╝╨╡╤В╤А╤Л.');
  }
  if (targetFruit is! String || !fruitSlugs.contains(targetFruit)) {
    return _fail('╨Э╨╡╨║╨╛╤А╤А╨╡╨║╤В╨╜╤Л╨╡ ╨┐╨░╤А╨░╨╝╨╡╤В╤А╤Л.');
  }
  if (!isTargetCountInAnswerRange(targetCount, answerRangeStart)) {
    return _fail('╨Я╤А╨░╨▓╨╕╨╗╤М╨╜╤Л╨╣ ╨╛╤В╨▓╨╡╤В ╨┤╨╛╨╗╨╢╨╡╨╜ ╨┐╨╛╨┐╨░╨┤╨░╤В╤М ╨▓ ╨┤╨╕╨░╨┐╨░╨╖╨╛╨╜ ╤З╨╡╤В╤Л╤А╤С╤Е ╨║╨╜╨╛╨┐╨╛╨║.');
  }
  if (totalFruits < targetCount) {
    return _fail('╨Т╤Б╨╡╨│╨╛ ╤Д╤А╤Г╨║╤В╨╛╨▓ ╨╜╨╡ ╨╝╨╛╨╢╨╡╤В ╨▒╤Л╤В╤М ╨╝╨╡╨╜╤М╤И╨╡, ╤З╨╡╨╝ ╨╕╤Б╨║╨╛╨╝╤Л╤Е.');
  }
  if (totalFruits < fruitTypeCount) {
    return _fail('╨Т╤Б╨╡╨│╨╛ ╤Д╤А╤Г╨║╤В╨╛╨▓ ╨┤╨╛╨╗╨╢╨╜╨╛ ╤Е╨▓╨░╤В╨░╤В╤М ╨╜╨░ ╨▓╤Б╨╡ ╨▓╨╕╨┤╤Л.');
  }
  if (totalFruits < targetCount + (fruitTypeCount - 1 > 0 ? fruitTypeCount - 1 : 0)) {
    return _fail('╨б╨╗╨╕╤И╨║╨╛╨╝ ╨╝╨░╨╗╨╛ ╤Д╤А╤Г╨║╤В╨╛╨▓ ╨┤╨╗╤П ╨▓╤Л╨▒╤А╨░╨╜╨╜╨╛╨│╨╛ ╤З╨╕╤Б╨╗╨░ ╨▓╨╕╨┤╨╛╨▓.');
  }
  return ValidateTrainerParamsResult.success({
    'answerRangeStart': answerRangeStart,
    'fruitTypeCount': fruitTypeCount,
    'targetCount': targetCount,
    'targetFruit': targetFruit,
    'totalFruits': totalFruits,
  });
}

ValidateTrainerParamsResult validateNumberCompositionParams(Map<String, dynamic> raw) {
  final answerRangeStart = coerceInt(raw['answerRangeStart']);
  final knownPart = coerceInt(raw['knownPart']);
  final whole = coerceInt(raw['whole']);

  if (answerRangeStart == null || answerRangeStart < 0 || answerRangeStart > 6) {
    return _fail('╨Э╨╡╨║╨╛╤А╤А╨╡╨║╤В╨╜╤Л╨╡ ╨┐╨░╤А╨░╨╝╨╡╤В╤А╤Л.');
  }
  if (knownPart == null || knownPart < 0 || knownPart > 8) {
    return _fail('╨Э╨╡╨║╨╛╤А╤А╨╡╨║╤В╨╜╤Л╨╡ ╨┐╨░╤А╨░╨╝╨╡╤В╤А╤Л.');
  }
  if (whole == null || whole < 2 || whole > 9) {
    return _fail('╨Э╨╡╨║╨╛╤А╤А╨╡╨║╤В╨╜╤Л╨╡ ╨┐╨░╤А╨░╨╝╨╡╤В╤А╤Л.');
  }
  if (knownPart >= whole) {
    return _fail('╨Ш╨╖╨▓╨╡╤Б╤В╨╜╨░╤П ╤З╨░╤Б╤В╤М ╨┤╨╛╨╗╨╢╨╜╨░ ╨▒╤Л╤В╤М ╨╝╨╡╨╜╤М╤И╨╡ ╤Ж╨╡╨╗╨╛╨│╨╛ ╤З╨╕╤Б╨╗╨░.');
  }
  final missingPart = whole - knownPart;
  if (!isMissingPartInDotRange(missingPart)) {
    return _fail('╨Ф╨╗╤П ╤В╨╛╤З╨╡╤З╨╜╨╛╨│╨╛ ╤Н╤В╨░╨┐╨░ ╨╛╤В╨▓╨╡╤В ╨┤╨╛╨╗╨╢╨╡╨╜ ╨▒╤Л╤В╤М ╨╛╤В 0 ╨┤╨╛ 3.');
  }
  if (!isMissingPartInDigitRange(missingPart, answerRangeStart)) {
    return _fail(
      '╨Я╤А╨░╨▓╨╕╨╗╤М╨╜╤Л╨╣ ╨╛╤В╨▓╨╡╤В ╨┤╨╛╨╗╨╢╨╡╨╜ ╨┐╨╛╨┐╨░╨┤╨░╤В╤М ╨▓ ╨┤╨╕╨░╨┐╨░╨╖╨╛╨╜ ╤З╨╡╤В╤Л╤А╤С╤Е ╨║╨╜╨╛╨┐╨╛╨║ ╤Б ╤Ж╨╕╤Д╤А╨░╨╝╨╕.',
    );
  }
  return ValidateTrainerParamsResult.success({
    'answerRangeStart': answerRangeStart,
    'knownPart': knownPart,
    'whole': whole,
  });
}

ValidateTrainerParamsResult validateShopPayParams(Map<String, dynamic> raw) {
  final coinCount = coerceInt(raw['coinCount']);
  final price = coerceInt(raw['price']);
  final item = raw['item'];

  if (coinCount == null || coinCount < 1 || coinCount > maxShopCoins) {
    return _fail('╨Э╨╡╨║╨╛╤А╤А╨╡╨║╤В╨╜╤Л╨╡ ╨┐╨░╤А╨░╨╝╨╡╤В╤А╤Л.');
  }
  if (price == null || price < 1 || price > maxShopPrice) {
    return _fail('╨Э╨╡╨║╨╛╤А╤А╨╡╨║╤В╨╜╤Л╨╡ ╨┐╨░╤А╨░╨╝╨╡╤В╤А╤Л.');
  }
  if (item is! String || !shopItemSlugs.contains(item)) {
    return _fail('╨Э╨╡╨║╨╛╤А╤А╨╡╨║╤В╨╜╤Л╨╡ ╨┐╨░╤А╨░╨╝╨╡╤В╤А╤Л.');
  }
  if (!isCoinCountValid(coinCount, price)) {
    return _fail('╨Ь╨╛╨╜╨╡╤В ╨┤╨╛╨╗╨╢╨╜╨╛ ╤Е╨▓╨░╤В╨╕╤В╤М, ╤З╤В╨╛╨▒╤Л ╤Б╨╛╨▒╤А╨░╤В╤М ╤Ж╨╡╨╜╤Г ╤В╨╛╨▓╨░╤А╨░.');
  }
  return ValidateTrainerParamsResult.success({
    'coinCount': coinCount,
    'item': item,
    'price': price,
  });
}

ValidateTrainerParamsResult validateDigitTraceParams(Map<String, dynamic> raw) {
  final digit = coerceInt(raw['digit']);
  if (digit == null || digit < 0 || digit > 9) {
    return _fail('╨Э╨╡╨║╨╛╤А╤А╨╡╨║╤В╨╜╤Л╨╡ ╨┐╨░╤А╨░╨╝╨╡╤В╤А╤Л.');
  }
  return ValidateTrainerParamsResult.success({'digit': digit});
}

ValidateTrainerParamsResult validateTopicChainFlashParams(Map<String, dynamic> raw) {
  final topicId = raw['topicId'];
  final actionCount = coerceInt(raw['actionCount']);
  final exampleCount = coerceInt(raw['exampleCount']) ?? 1;
  final stepPauseSec = coerceDouble(raw['stepPauseSec']);

  if (topicId is! String || !isTopicId(topicId)) {
    return _fail('╨Э╨╡╨║╨╛╤А╤А╨╡╨║╤В╨╜╤Л╨╡ ╨┐╨░╤А╨░╨╝╨╡╤В╤А╤Л.');
  }
  if (actionCount == null ||
      actionCount < kActionCountMin ||
      actionCount > kActionCountMax) {
    return _fail('╨Э╨╡╨║╨╛╤А╤А╨╡╨║╤В╨╜╤Л╨╡ ╨┐╨░╤А╨░╨╝╨╡╤В╤А╤Л.');
  }
  if (exampleCount < 1 || exampleCount > 10) {
    return _fail('╨Э╨╡╨║╨╛╤А╤А╨╡╨║╤В╨╜╤Л╨╡ ╨┐╨░╤А╨░╨╝╨╡╤В╤А╤Л.');
  }
  if (stepPauseSec == null || stepPauseSec < 0.1 || stepPauseSec > 30) {
    return _fail('╨Э╨╡╨║╨╛╤А╤А╨╡╨║╤В╨╜╤Л╨╡ ╨┐╨░╤А╨░╨╝╨╡╤В╤А╤Л.');
  }

  final solveMode = raw['solveMode'] == 'mental' ? 'mental' : 'abacus';

  return ValidateTrainerParamsResult.success({
    'actionCount': actionCount,
    'exampleCount': exampleCount,
    'solveMode': solveMode,
    'stepPauseSec': stepPauseSec,
    'topicId': topicId,
  });
}

ValidateTrainerParamsResult validateTopicChainTableParams(Map<String, dynamic> raw) {
  final topicId = raw['topicId'];
  final actionCount = coerceInt(raw['actionCount']);
  final exampleCount = coerceInt(raw['exampleCount']) ?? 5;

  if (topicId is! String || !isTopicId(topicId)) {
    return _fail('╨Э╨╡╨║╨╛╤А╤А╨╡╨║╤В╨╜╤Л╨╡ ╨┐╨░╤А╨░╨╝╨╡╤В╤А╤Л.');
  }
  if (actionCount == null ||
      actionCount < kActionCountMin ||
      actionCount > kActionCountMax) {
    return _fail('╨Э╨╡╨║╨╛╤А╤А╨╡╨║╤В╨╜╤Л╨╡ ╨┐╨░╤А╨░╨╝╨╡╤В╤А╤Л.');
  }
  if (exampleCount < 1 || exampleCount > 12) {
    return _fail('╨Э╨╡╨║╨╛╤А╤А╨╡╨║╤В╨╜╤Л╨╡ ╨┐╨░╤А╨░╨╝╨╡╤В╤А╤Л.');
  }

  return ValidateTrainerParamsResult.success({
    'actionCount': actionCount,
    'exampleCount': exampleCount,
    'topicId': topicId,
  });
}

ValidateTrainerParamsResult validateFlashcardDigitMatchParams(Map<String, dynamic> raw) {
  var pairCount = coerceInt(raw['pairCount']);
  var rounds = coerceInt(raw['rounds']);
  final legacyValues = coerceIntList(raw['values']);

  if (pairCount == null && legacyValues != null) {
    pairCount = legacyValues.length;
  }

  rounds ??= minMatchRounds;
  final targetMode = normalizeTargetMode(raw['targetMode']);
  final topicId = resolveMatchTopicId(
    raw['topicId'] ?? raw['chainTopicId'],
    raw['totalRods'],
  );

  if (pairCount == null ||
      pairCount < minMatchPairs ||
      pairCount > maxMatchPairs) {
    return _fail('╨Э╨╡╨║╨╛╤А╤А╨╡╨║╤В╨╜╤Л╨╡ ╨┐╨░╤А╨░╨╝╨╡╤В╤А╤Л.');
  }
  if (rounds == null || rounds < minMatchRounds || rounds > maxMatchRounds) {
    return _fail('╨Э╨╡╨║╨╛╤А╤А╨╡╨║╤В╨╜╤Л╨╡ ╨┐╨░╤А╨░╨╝╨╡╤В╤А╤Л.');
  }

  return ValidateTrainerParamsResult.success({
    'topicId': topicId,
    'pairCount': pairCount,
    'rounds': rounds,
    'targetMode':
        targetMode == FlashcardTargetMode.dots ? 'dots' : 'digits',
  });
}

ValidateTrainerParamsResult validateFlyTrackParams(Map<String, dynamic> raw) {
  final gridSize = coerceInt(raw['gridSize']) ?? kFlyTrackGridSizeDefault;
  final rounds = coerceInt(raw['rounds']) ?? kFlyTrackRoundsDefault;
  final stepCount = coerceInt(raw['stepCount']) ?? kFlyTrackStepCountDefault;
  final stepPauseSec =
      coerceDouble(raw['stepPauseSec']) ?? kFlyTrackStepPauseSecDefault;

  if (gridSize < kFlyTrackGridSizeMin || gridSize > kFlyTrackGridSizeMax) {
    return _fail('╨Э╨╡╨║╨╛╤А╤А╨╡╨║╤В╨╜╤Л╨╡ ╨┐╨░╤А╨░╨╝╨╡╤В╤А╤Л.');
  }
  if (rounds < kFlyTrackRoundsMin || rounds > kFlyTrackRoundsMax) {
    return _fail('╨Э╨╡╨║╨╛╤А╤А╨╡╨║╤В╨╜╤Л╨╡ ╨┐╨░╤А╨░╨╝╨╡╤В╤А╤Л.');
  }
  if (stepCount < kFlyTrackStepCountMin || stepCount > kFlyTrackStepCountMax) {
    return _fail('╨Э╨╡╨║╨╛╤А╤А╨╡╨║╤В╨╜╤Л╨╡ ╨┐╨░╤А╨░╨╝╨╡╤В╤А╤Л.');
  }
  if (stepPauseSec < kFlyTrackStepPauseSecMin ||
      stepPauseSec > kFlyTrackStepPauseSecMax) {
    return _fail('╨Э╨╡╨║╨╛╤А╤А╨╡╨║╤В╨╜╤Л╨╡ ╨┐╨░╤А╨░╨╝╨╡╤В╤А╤Л.');
  }

  return ValidateTrainerParamsResult.success({
    'gridSize': gridSize,
    'rounds': rounds,
    'stepCount': stepCount,
    'stepPauseSec': stepPauseSec,
  });
}
