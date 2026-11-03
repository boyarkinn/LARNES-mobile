import 'package:larnes_mobile/trainers/catalog/validate_trainer_params_result.dart';
import 'package:larnes_mobile/trainers/reading/letter_model.dart';
import 'package:larnes_mobile/trainers/reading/syllable_pair_connect/syllable_pair_connect_model.dart';

ValidateTrainerParamsResult validateSyllablePairConnectParams(Map<String, dynamic> raw) {
  final value = raw.containsKey('practiceLetters') ? raw['practiceLetters'] : defaultPairVowels;
  final letterCase = raw.containsKey('letterCase') ? raw['letterCase'] : 'upper';
  final syllableType = raw.containsKey('syllableType') ? raw['syllableType'] : 'all';
  final rawCount = raw.containsKey('pairCount') ? raw['pairCount'] : 5;
  final count = rawCount is num ? rawCount : rawCount is String ? num.tryParse(rawCount.trim()) : rawCount == true ? 1 : null;
  if (value is! String || value.trim().isEmpty || value.trim().length > 128 ||
      letterCase is! String || !letterCaseValues.contains(letterCase) ||
      syllableType is! String || !syllableTypes.contains(syllableType) ||
      count == null || !count.isFinite || count != count.truncateToDouble() || count < 1 || count > 12) {
    return const ValidateTrainerParamsResult.failure('Некорректные параметры.');
  }
  final vowels = parsePairVowels(value);
  if (vowels.isEmpty || value.toUpperCase().contains(RegExp(r'[^АОУЫЭЯЁЮИЕ,;\s]'))) {
    return const ValidateTrainerParamsResult.failure('Выберите хотя бы одну гласную: А, О, У, Ы, Э, Я, Ё, Ю, И, Е.');
  }
  return ValidateTrainerParamsResult.success({'practiceLetters': vowels.join(','), 'pairCount': count.toInt(), 'letterCase': letterCase, 'syllableType': syllableType});
}
