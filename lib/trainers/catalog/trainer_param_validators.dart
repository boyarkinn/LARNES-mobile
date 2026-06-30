import 'package:larnes_mobile/trainers/catalog/validate_trainer_params_result.dart';
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

ValidateTrainerParamsResult validateFlashcardDigitMatchParams(Map<String, dynamic> raw) {
  final totalRods = coerceInt(raw['totalRods']);
  final values = coerceIntList(raw['values']);

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
