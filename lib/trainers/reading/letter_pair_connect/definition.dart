import 'package:larnes_mobile/trainers/catalog/validate_trainer_params_result.dart';
import 'package:larnes_mobile/trainers/reading/letter_model.dart';
import 'package:larnes_mobile/trainers/reading/letter_pair_connect/letter_pair_connect_model.dart';

ValidateTrainerParamsResult validateLetterPairConnectParams(Map<String, dynamic> raw) {
  final value = raw.containsKey('practiceLetters') ? raw['practiceLetters'] : defaultPairLetters;
  final letterCase = raw.containsKey('letterCase') ? raw['letterCase'] : 'upper';
  if (value is! String || value.trim().isEmpty || value.trim().length > 256 ||
      letterCase is! String || !letterCaseValues.contains(letterCase)) {
    return const ValidateTrainerParamsResult.failure('Некорректные параметры.');
  }
  final letters = parsePairLetters(value);
  if (letters.isEmpty) {
    return const ValidateTrainerParamsResult.failure('Укажите русские буквы через запятую.');
  }
  return ValidateTrainerParamsResult.success({'practiceLetters': letters.join(','), 'letterCase': letterCase});
}
