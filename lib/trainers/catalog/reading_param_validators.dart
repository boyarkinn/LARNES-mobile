import 'package:larnes_mobile/trainers/catalog/validate_trainer_params_result.dart';
import 'package:larnes_mobile/trainers/reading/letter_guide_model.dart';
import 'package:larnes_mobile/trainers/reading/letter_model.dart';
import 'package:larnes_mobile/trainers/reading/reading_word_catalogs.dart';
import 'package:larnes_mobile/trainers/reading/zaitsev_catalog.dart';
import 'package:larnes_mobile/trainers/shared/param_coerce.dart';

ValidateTrainerParamsResult _fail(String message) {
  return ValidateTrainerParamsResult.failure(message);
}

const _russianLetterMessage = 'Укажите одну русскую букву (А–Я, без Ё).';
const _practiceLettersMessage =
    'Укажите хотя бы одну русскую букву (А–Я, без Ё), через запятую.';

ValidateTrainerParamsResult _validateSingleLetterField(
  Map<String, dynamic> raw, {
  bool requireRussian = true,
}) {
  final letterRaw = raw['letter'];
  if (letterRaw is! String || letterRaw.trim().isEmpty || letterRaw.trim().length > 8) {
    return _fail('Некорректные параметры.');
  }
  if (requireRussian && !isRussianLetterWithoutYo(letterRaw)) {
    return _fail(_russianLetterMessage);
  }
  return ValidateTrainerParamsResult.success({});
}

ValidateTrainerParamsResult _withLetterCase(
  Map<String, dynamic> raw,
  Map<String, dynamic> params,
) {
  final letterCase = parseLetterCase(raw['letterCase']);
  if (letterCase == null) {
    return _fail('Некорректные параметры.');
  }
  return ValidateTrainerParamsResult.success({
    ...params,
    'letterCase': letterCase,
  });
}

ValidateTrainerParamsResult validateLetterFindTapParams(Map<String, dynamic> raw) {
  final letterResult = _validateSingleLetterField(raw);
  if (!letterResult.ok) {
    return letterResult;
  }
  final targetCount = coerceInt(raw['targetCount']);
  final distractorCount = coerceInt(raw['distractorCount']);
  if (targetCount == null || targetCount < 1 || targetCount > 9) {
    return _fail('Некорректные параметры.');
  }
  if (distractorCount == null || distractorCount < 0 || distractorCount > 30) {
    return _fail('Некорректные параметры.');
  }
  if (!canFitLetterField(targetCount, distractorCount)) {
    return _fail('Слишком много букв на экране (максимум $maxLetterFieldTokens).');
  }
  final letterCaseResult = _withLetterCase(raw, {
    'letter': normalizeTargetLetter(raw['letter'] as String),
    'targetCount': targetCount,
    'distractorCount': distractorCount,
  });
  return letterCaseResult;
}

ValidateTrainerParamsResult validateLetterFindBySoundParams(Map<String, dynamic> raw) {
  final letterResult = _validateSingleLetterField(raw);
  if (!letterResult.ok) {
    return letterResult;
  }
  final distractorCount = coerceInt(raw['distractorCount']);
  if (distractorCount == null || distractorCount < 0 || distractorCount > 30) {
    return _fail('Некорректные параметры.');
  }
  if (!canFitSoundFindField(distractorCount)) {
    return _fail('Слишком много букв на экране (максимум $maxLetterFieldTokens).');
  }
  return _withLetterCase(raw, {
    'letter': normalizeTargetLetter(raw['letter'] as String),
    'distractorCount': distractorCount,
  });
}

ValidateTrainerParamsResult validateLetterTraceParams(Map<String, dynamic> raw) {
  final letterResult = _validateSingleLetterField(raw);
  if (!letterResult.ok) {
    return letterResult;
  }
  return _withLetterCase(raw, {
    'letter': normalizeTargetLetter(raw['letter'] as String),
  });
}

ValidateTrainerParamsResult validateLetterHalfDrawParams(Map<String, dynamic> raw) {
  return validateLetterTraceParams(raw);
}

ValidateTrainerParamsResult validateLetterColorParams(Map<String, dynamic> raw) {
  return validateLetterTraceParams(raw);
}

ValidateTrainerParamsResult validateLetterCaseColorParams(Map<String, dynamic> raw) {
  final letterResult = _validateSingleLetterField(raw);
  if (!letterResult.ok) {
    return letterResult;
  }
  return ValidateTrainerParamsResult.success({
    'letter': normalizeTargetLetter(raw['letter'] as String),
  });
}

ValidateTrainerParamsResult validateLetterConnectDotsParams(Map<String, dynamic> raw) {
  final letterResult = _validateSingleLetterField(raw);
  if (!letterResult.ok) {
    return letterResult;
  }
  final dotMode = raw['dotMode']?.toString() ?? 'free';
  if (!dotModeValues.contains(dotMode)) {
    return _fail('Некорректные параметры.');
  }
  return _withLetterCase(raw, {
    'dotMode': dotMode,
    'letter': normalizeTargetLetter(raw['letter'] as String),
  });
}

ValidateTrainerParamsResult validateLetterBuildParams(Map<String, dynamic> raw) {
  final letterResult = _validateSingleLetterField(raw);
  if (!letterResult.ok) {
    return letterResult;
  }
  final letter = normalizeTargetLetter(raw['letter'] as String);
  if (!isSupportedBuildLetter(letter)) {
    return _fail('Для этой буквы пока нет палочек в каталоге.');
  }
  return _withLetterCase(raw, {'letter': letter});
}

ValidateTrainerParamsResult validateLetterDrawShowParams(Map<String, dynamic> raw) {
  final letterRaw = raw['letter'];
  if (letterRaw is! String || letterRaw.trim().isEmpty || letterRaw.trim().length > 8) {
    return _fail('Некорректные параметры.');
  }
  final rounds = coerceInt(raw['rounds']) ?? 1;
  if (rounds < 1 || rounds > 5) {
    return _fail('Некорректные параметры.');
  }
  final letter = normalizeDrawShowLetter(letterRaw);
  if (!isSupportedDrawShowLetter(letter)) {
    return _fail('Для этой буквы пока нет графического образа.');
  }
  return _withLetterCase(raw, {
    'letter': letter,
    'rounds': rounds,
  });
}

ValidateTrainerParamsResult validateLetterCompleteParams(Map<String, dynamic> raw) {
  final letterResult = _validateSingleLetterField(raw);
  if (!letterResult.ok) {
    return letterResult;
  }
  final letter = normalizeTargetLetter(raw['letter'] as String);
  if (!isCompletableLetter(letter)) {
    return _fail('Букву «$letter» пока нельзя дописать (нужно минимум 2 штриха).');
  }
  final missingSegment = normalizeMissingSegmentParam(raw['missingSegment'] ?? 'random');
  if (!isValidMissingSegment(letter, missingSegment)) {
    return _fail('Укажите номер штриха от 0 или random.');
  }
  return _withLetterCase(raw, {
    'letter': letter,
    'missingSegment': missingSegment,
  });
}

ValidateTrainerParamsResult validateLetterOrientationPickParams(Map<String, dynamic> raw) {
  final letterResult = _validateSingleLetterField(raw);
  if (!letterResult.ok) {
    return letterResult;
  }
  final entityCount = coerceInt(raw['entityCount']) ?? 4;
  if (entityCount < 4 || entityCount > 6) {
    return _fail('Некорректные параметры.');
  }
  final letter = normalizeTargetLetter(raw['letter'] as String);
  if (!isOrientationPickableLetter(letter)) {
    return _fail('Букву «$letter» пока нельзя использовать (поворот не отличим от эталона).');
  }
  return _withLetterCase(raw, {
    'entityCount': entityCount,
    'letter': letter,
  });
}

ValidateTrainerParamsResult validateLetterOddOneOutParams(Map<String, dynamic> raw) {
  final letterResult = _validateSingleLetterField(raw);
  if (!letterResult.ok) {
    return letterResult;
  }
  final letterCount = coerceInt(raw['letterCount']) ?? 10;
  if (letterCount < 6 || letterCount > 12) {
    return _fail('Некорректные параметры.');
  }
  final letter = normalizeTargetLetter(raw['letter'] as String);
  final oddRaw = raw['oddLetter'] ?? 'random';
  final oddLetter = oddRaw == 'random'
      ? 'random'
      : normalizeTargetLetter(oddRaw.toString());
  if (oddLetter != 'random' && !isRussianLetterWithoutYo(oddLetter.toString())) {
    return _fail('Укажите одну русскую букву (А–Я, без Ё) или random.');
  }
  if (!isValidOddLetterParam(letter, oddLetter)) {
    return _fail('Лишняя буква должна отличаться от основной.');
  }
  return _withLetterCase(raw, {
    'letter': letter,
    'letterCount': letterCount,
    'oddLetter': oddLetter,
  });
}

ValidateTrainerParamsResult validateLetterFirstByImageParams(Map<String, dynamic> raw) {
  final distractorCount = coerceInt(raw['distractorCount']) ?? 3;
  if (distractorCount < 0 || distractorCount > 7) {
    return _fail('Некорректные параметры.');
  }
  if (!canFitLetterChoices(distractorCount)) {
    return _fail('Слишком много кнопок с буквами (максимум $maxLetterChoices).');
  }
  final letterCase = parseLetterCase(raw['letterCase']);
  final wordCase = parseLetterCase(raw['wordCase']);
  if (letterCase == null || wordCase == null) {
    return _fail('Некорректные параметры.');
  }
  return ValidateTrainerParamsResult.success({
    'distractorCount': distractorCount,
    'letterCase': letterCase,
    'wordCase': wordCase,
    'wordSlug': normalizeFirstByImageWordSlug(raw['wordSlug']?.toString() ?? 'stork'),
  });
}

ValidateTrainerParamsResult validateLetterWordLinkParams(Map<String, dynamic> raw) {
  final entityCount = coerceInt(raw['entityCount']) ?? 4;
  if (entityCount < minWordLinkItems || entityCount > maxWordLinkItems) {
    return _fail('Некорректные параметры.');
  }
  final letterCase = parseLetterCase(raw['letterCase']);
  final wordCase = parseLetterCase(raw['wordCase']);
  if (letterCase == null || wordCase == null) {
    return _fail('Некорректные параметры.');
  }
  final letter = normalizeTargetLetter((raw['letter'] ?? 'А').toString());
  if (!canBuildWordLinkRound(letter, entityCount)) {
    return _fail(
      'Недостаточно предметов на букву «$letter» для $entityCount карточек.',
    );
  }
  return ValidateTrainerParamsResult.success({
    'entityCount': entityCount,
    'letter': letter,
    'letterCase': letterCase,
    'wordCase': wordCase,
  });
}

ValidateTrainerParamsResult validateLetterPlaceInWordParams(Map<String, dynamic> raw) {
  final practiceRaw = raw['practiceLetters'];
  if (practiceRaw is! String || practiceRaw.trim().isEmpty || practiceRaw.trim().length > 64) {
    return _fail('Некорректные параметры.');
  }
  final practiceLetters = parsePracticeLetters(practiceRaw);
  if (practiceLetters.isEmpty) {
    return _fail(_practiceLettersMessage);
  }
  final distractorCount = coerceInt(raw['distractorCount']) ?? 3;
  final entityCount = coerceInt(raw['entityCount']) ?? 1;
  if (distractorCount < 0 || distractorCount > 12) {
    return _fail('Некорректные параметры.');
  }
  if (entityCount < 1 || entityCount > maxEntityCount) {
    return _fail('Некорректные параметры.');
  }
  if (!canFitLetterPool(entityCount, distractorCount)) {
    return _fail('Слишком много букв в лотке (максимум $maxPoolLetters).');
  }
  final eligible = countEligibleFillGapWords(practiceLetters);
  if (eligible < entityCount) {
    return _fail(
      'Недостаточно слов для букв ${formatPracticeLetters(practiceLetters)} (нужно $entityCount, доступно $eligible).',
    );
  }
  final letterCase = parseLetterCase(raw['letterCase']);
  final wordCase = parseLetterCase(raw['wordCase']);
  if (letterCase == null || wordCase == null) {
    return _fail('Некорректные параметры.');
  }
  return ValidateTrainerParamsResult.success({
    'distractorCount': distractorCount,
    'entityCount': entityCount,
    'letterCase': letterCase,
    'practiceLetters': formatPracticeLetters(practiceLetters),
    'wordCase': wordCase,
  });
}

ValidateTrainerParamsResult validateLetterCaseMatchParams(Map<String, dynamic> raw) {
  final practiceRaw = raw['practiceLetters'];
  if (practiceRaw is! String || practiceRaw.trim().isEmpty || practiceRaw.trim().length > 64) {
    return _fail('Некорректные параметры.');
  }
  final practiceLetters = parsePracticeLetters(practiceRaw);
  if (practiceLetters.isEmpty) {
    return _fail(_practiceLettersMessage);
  }
  final pairCount = coerceInt(raw['pairCount']) ?? 3;
  if (pairCount < minPairCount || pairCount > maxPairCount) {
    return _fail('Некорректные параметры.');
  }
  if (!canUsePairCount(practiceLetters, pairCount)) {
    return _fail(
      'Нужно $pairCount пар, но доступно букв: ${practiceLetters.length} (максимум $maxPairCount).',
    );
  }
  return ValidateTrainerParamsResult.success({
    'pairCount': pairCount,
    'practiceLetters': formatPracticeLetters(practiceLetters),
  });
}

ValidateTrainerParamsResult validateLetterGridMatchParams(Map<String, dynamic> raw) {
  final practiceRaw = raw['practiceLetters'];
  if (practiceRaw is! String || practiceRaw.trim().isEmpty || practiceRaw.trim().length > 64) {
    return _fail('Некорректные параметры.');
  }
  final practiceLetters = parsePracticeLetters(practiceRaw);
  if (practiceLetters.isEmpty) {
    return _fail(_practiceLettersMessage);
  }
  final filledCount = coerceInt(raw['filledCount']) ?? 4;
  final gridSize = coerceInt(raw['gridSize']) ?? 3;
  if (!isValidGridSize(gridSize)) {
    return _fail('Размер сетки: 2 или 3.');
  }
  if (!isValidFilledCount(gridSize, filledCount)) {
    return _fail('Ячеек с буквами: от $minGridFilledCount до ${getMaxFilledCount(gridSize)}.');
  }
  final letterCase = parseLetterCase(raw['letterCase']);
  if (letterCase == null) {
    return _fail('Некорректные параметры.');
  }
  return ValidateTrainerParamsResult.success({
    'filledCount': filledCount,
    'gridSize': gridSize,
    'letterCase': letterCase,
    'practiceLetters': formatPracticeLetters(practiceLetters),
  });
}

ValidateTrainerParamsResult validateLetterNameAloudParams(Map<String, dynamic> raw) {
  final practiceRaw = raw['practiceLetters'];
  if (practiceRaw is! String || practiceRaw.trim().isEmpty || practiceRaw.trim().length > 64) {
    return _fail('Некорректные параметры.');
  }
  final practiceLetters = parsePracticeLetters(practiceRaw);
  if (practiceLetters.isEmpty || practiceLetters.length > maxPracticeLettersNameAloud) {
    return _fail(_practiceLettersMessage);
  }
  final displaySeconds = coerceInt(raw['displaySeconds']) ?? 3;
  if (displaySeconds < 2 || displaySeconds > 8) {
    return _fail('Некорректные параметры.');
  }
  final letterCase = parseLetterCase(raw['letterCase']);
  if (letterCase == null) {
    return _fail('Некорректные параметры.');
  }
  return ValidateTrainerParamsResult.success({
    'displaySeconds': displaySeconds,
    'letterCase': letterCase,
    'practiceLetters': formatPracticeLetters(practiceLetters),
  });
}

ValidateTrainerParamsResult validateLetterMarqueeTapParams(Map<String, dynamic> raw) {
  final practiceRaw = raw['practiceLetters'];
  if (practiceRaw is! String || practiceRaw.trim().isEmpty || practiceRaw.trim().length > 64) {
    return _fail('Некорректные параметры.');
  }
  final practiceLetters = parsePracticeLetters(practiceRaw);
  if (practiceLetters.isEmpty) {
    return _fail(_practiceLettersMessage);
  }
  final targetCount = coerceInt(raw['targetCount']) ?? 5;
  if (targetCount < 1 || targetCount > 20) {
    return _fail('Некорректные параметры.');
  }
  final speed = raw['speed']?.toString() ?? 'medium';
  if (!marqueeSpeedValues.contains(speed)) {
    return _fail('Некорректные параметры.');
  }
  final letterCase = parseLetterCase(raw['letterCase']);
  if (letterCase == null) {
    return _fail('Некорректные параметры.');
  }
  return ValidateTrainerParamsResult.success({
    'letterCase': letterCase,
    'practiceLetters': formatPracticeLetters(practiceLetters),
    'speed': speed,
    'targetCount': targetCount,
  });
}
