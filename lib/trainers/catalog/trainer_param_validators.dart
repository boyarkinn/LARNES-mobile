import 'package:larnes_mobile/trainers/catalog/validate_trainer_params_result.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/topics.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/types.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/flashcard_digit_match/flashcard_digit_match_model.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/static_example_show/example_logic.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/example_visualization/example_parser.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/example_visualization/step_planner.dart';
import 'package:larnes_mobile/trainers/shared/param_coerce.dart';
import 'package:larnes_mobile/trainers/shared/trainer_constants.dart';

ValidateTrainerParamsResult _fail(String message) {
  return ValidateTrainerParamsResult.failure(message);
}

ValidateTrainerParamsResult validateNumberRowShowParams(Map<String, dynamic> raw) {
  final digit = coerceInt(raw['digit']);
  if (digit == null || digit < 0 || digit > 9) {
    return _fail('Некорректные параметры.');
  }
  return ValidateTrainerParamsResult.success({'digit': digit});
}

ValidateTrainerParamsResult validateAppleCountShowParams(Map<String, dynamic> raw) {
  final digit = coerceInt(raw['digit']);
  if (digit == null || digit < 0) {
    return _fail('Некорректные параметры.');
  }
  return ValidateTrainerParamsResult.success({'digit': digit});
}

ValidateTrainerParamsResult validateAbacusShowParams(Map<String, dynamic> raw) {
  final totalRods = coerceInt(raw['totalRods']);
  final value = coerceInt(raw['value']);
  if (totalRods == null || totalRods < 1 || totalRods > 21) {
    return _fail('Некорректные параметры.');
  }
  if (value == null || value < 0) {
    return _fail('Некорректные параметры.');
  }
  final maxValue = getMaxValueForRods(totalRods);
  if (value > maxValue) {
    return _fail(
      'Число не помещается в $totalRods разряд(ов) (макс. $maxValue)',
    );
  }
  return ValidateTrainerParamsResult.success({
    'totalRods': totalRods,
    'value': value,
  });
}

ValidateTrainerParamsResult validateDotsDigitAbacusParams(Map<String, dynamic> raw) {
  return validateAbacusShowParams(raw);
}

ValidateTrainerParamsResult validateStaticExampleShowParams(Map<String, dynamic> raw) {
  final operation = raw['operation'];
  final operandA = coerceInt(raw['operandA']);
  final operandB = coerceInt(raw['operandB']);
  final totalRods = coerceInt(raw['totalRods']);

  if (operation is! String || !isStaticExampleOperation(operation)) {
    return _fail('Некорректные параметры.');
  }
  if (operandA == null || operandA < 0 || operandA > 99) {
    return _fail('Некорректные параметры.');
  }
  if (operandB == null || operandB < 0 || operandB > 99) {
    return _fail('Некорректные параметры.');
  }
  if (totalRods == null || totalRods < 1 || totalRods > 2) {
    return _fail('Некорректные параметры.');
  }

  final maxValue = maxValueForRods(totalRods);

  if (operandA > maxValue) {
    return _fail(
      'Первое число не помещается в $totalRods разряд(ов) (макс. $maxValue)',
    );
  }

  if (operation == 'subtract' && operandA < operandB) {
    return _fail('При вычитании первое число не может быть меньше второго.');
  }

  final values = resolveStaticExampleAbacusValues(
    operation: operation,
    operandA: operandA,
    operandB: operandB,
  );

  if (values.rightValue < 0) {
    return _fail('Ответ не может быть отрицательным.');
  }

  if (values.rightValue > maxValue) {
    return _fail(
      'Ответ не помещается в $totalRods разряд(ов) (макс. $maxValue)',
    );
  }

  if (values.leftValue > maxValue) {
    return _fail(
      'Левый абакус не помещается в $totalRods разряд(ов) (макс. $maxValue)',
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
    return _fail('Некорректные параметры.');
  }
  if (stepPauseSec == null || stepPauseSec < 0.5 || stepPauseSec > 30) {
    return _fail('Некорректные параметры.');
  }
  if (totalRods == null || totalRods < 1 || totalRods > 2) {
    return _fail('Некорректные параметры.');
  }

  final trimmedExample = example.trim();
  late final List<ExampleAction> actions;

  try {
    actions = parseExampleActions(trimmedExample);
  } on FormatException catch (error) {
    return _fail(error.message);
  } catch (_) {
    return _fail('Неверный формат примера.');
  }

  final normalizedExample = formatExample(actions);

  final stateError = validateExampleForRods(normalizedExample, totalRods);
  final planError = validateExamplePlan(normalizedExample, totalRods);
  final message = stateError ?? planError;

  if (message != null) {
    return _fail(message);
  }

  return ValidateTrainerParamsResult.success({
    'example': normalizedExample,
    'stepPauseSec': stepPauseSec,
    'totalRods': totalRods,
  });
}

ValidateTrainerParamsResult validateDigitFindTapParams(Map<String, dynamic> raw) {
  final digit = coerceInt(raw['digit']);
  final distractorCount = coerceInt(raw['distractorCount']);
  final targetCount = coerceInt(raw['targetCount']);
  if (digit == null || digit < 0 || digit > 9) {
    return _fail('Некорректные параметры.');
  }
  if (distractorCount == null || distractorCount < 0 || distractorCount > 30) {
    return _fail('Некорректные параметры.');
  }
  if (targetCount == null || targetCount < 1 || targetCount > 9) {
    return _fail('Некорректные параметры.');
  }
  if (targetCount + distractorCount > maxDigitFieldTokens) {
    return _fail('Слишком много цифр на экране (максимум $maxDigitFieldTokens).');
  }
  return ValidateTrainerParamsResult.success({
    'digit': digit,
    'distractorCount': distractorCount,
    'targetCount': targetCount,
  });
}

ValidateTrainerParamsResult validateFruitCountTapParams(Map<String, dynamic> raw) {
  final answerRangeStart = coerceInt(raw['answerRangeStart']);
  final fruitTypeCount = coerceInt(raw['fruitTypeCount']);
  final targetCount = coerceInt(raw['targetCount']);
  final totalFruits = coerceInt(raw['totalFruits']);
  final targetFruit = raw['targetFruit'];

  if (answerRangeStart == null || answerRangeStart < 0 || answerRangeStart > 6) {
    return _fail('Некорректные параметры.');
  }
  if (fruitTypeCount == null || fruitTypeCount < 1 || fruitTypeCount > 10) {
    return _fail('Некорректные параметры.');
  }
  if (targetCount == null || targetCount < 0 || targetCount > 9) {
    return _fail('Некорректные параметры.');
  }
  if (totalFruits == null || totalFruits < 1 || totalFruits > maxFruitFieldTokens) {
    return _fail('Некорректные параметры.');
  }
  if (targetFruit is! String || !fruitSlugs.contains(targetFruit)) {
    return _fail('Некорректные параметры.');
  }
  if (!isTargetCountInAnswerRange(targetCount, answerRangeStart)) {
    return _fail('Правильный ответ должен попадать в диапазон четырёх кнопок.');
  }
  if (totalFruits < targetCount) {
    return _fail('Всего фруктов не может быть меньше, чем искомых.');
  }
  if (totalFruits < fruitTypeCount) {
    return _fail('Всего фруктов должно хватать на все виды.');
  }
  if (totalFruits < targetCount + (fruitTypeCount - 1 > 0 ? fruitTypeCount - 1 : 0)) {
    return _fail('Слишком мало фруктов для выбранного числа видов.');
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
    return _fail('Некорректные параметры.');
  }
  if (knownPart == null || knownPart < 0 || knownPart > 8) {
    return _fail('Некорректные параметры.');
  }
  if (whole == null || whole < 2 || whole > 9) {
    return _fail('Некорректные параметры.');
  }
  if (knownPart >= whole) {
    return _fail('Известная часть должна быть меньше целого числа.');
  }
  final missingPart = whole - knownPart;
  if (!isMissingPartInDotRange(missingPart)) {
    return _fail('Для точечного этапа ответ должен быть от 0 до 3.');
  }
  if (!isMissingPartInDigitRange(missingPart, answerRangeStart)) {
    return _fail(
      'Правильный ответ должен попадать в диапазон четырёх кнопок с цифрами.',
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
    return _fail('Некорректные параметры.');
  }
  if (price == null || price < 1 || price > maxShopPrice) {
    return _fail('Некорректные параметры.');
  }
  if (item is! String || !shopItemSlugs.contains(item)) {
    return _fail('Некорректные параметры.');
  }
  if (!isCoinCountValid(coinCount, price)) {
    return _fail('Монет должно быть не меньше цены товара.');
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
    return _fail('Некорректные параметры.');
  }
  return ValidateTrainerParamsResult.success({'digit': digit});
}

ValidateTrainerParamsResult validateTopicChainFlashParams(Map<String, dynamic> raw) {
  final topicId = raw['topicId'];
  final actionCount = coerceInt(raw['actionCount']);
  final signMode = raw['signMode'];
  final amountScopeRaw = raw['amountScope'];
  final stepPauseSec = coerceDouble(raw['stepPauseSec']);

  if (topicId is! String || !isTopicId(topicId)) {
    return _fail('Некорректные параметры.');
  }
  if (actionCount == null ||
      actionCount < kActionCountMin ||
      actionCount > kActionCountMax) {
    return _fail('Некорректные параметры.');
  }
  if (signMode is! String || !isSignMode(signMode)) {
    return _fail('Некорректные параметры.');
  }

  final amountScope = amountScopeRaw == null || amountScopeRaw == ''
      ? 'topic'
      : amountScopeRaw;
  if (amountScope is! String || !isAmountScope(amountScope)) {
    return _fail('Некорректные параметры.');
  }
  if (stepPauseSec == null || stepPauseSec < 0.1 || stepPauseSec > 30) {
    return _fail('Некорректные параметры.');
  }

  return ValidateTrainerParamsResult.success({
    'actionCount': actionCount,
    'amountScope': amountScope,
    'signMode': signMode,
    'stepPauseSec': stepPauseSec,
    'topicId': topicId,
  });
}

ValidateTrainerParamsResult validateFlashcardDigitMatchParams(Map<String, dynamic> raw) {
  final totalRods = coerceInt(raw['totalRods']);
  var values = coerceIntList(raw['values']);
  values ??= parseMatchValuesFromInput(
    pairCount: raw['pairCount'],
    value0: raw['value0'],
    value1: raw['value1'],
    value2: raw['value2'],
    value3: raw['value3'],
  );

  if (totalRods == null || totalRods < 1 || totalRods > 21) {
    return _fail('Некорректные параметры.');
  }
  if (values == null ||
      values.length < minMatchPairs ||
      values.length > maxMatchPairs) {
    return _fail('Некорректные параметры.');
  }
  if (!areFlashcardValuesValid(values, totalRods)) {
    return _fail(
      'Числа должны быть уникальными и помещаться в выбранное число разрядов.',
    );
  }
  return ValidateTrainerParamsResult.success({
    'totalRods': totalRods,
    'values': values,
  });
}
