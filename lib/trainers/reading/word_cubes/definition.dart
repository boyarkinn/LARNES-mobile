import 'package:larnes_mobile/trainers/catalog/validate_trainer_params_result.dart';

ValidateTrainerParamsResult validateWordCubesParams(Map<String, dynamic> raw) {
  final slug = raw.containsKey('wordSlug') ? raw['wordSlug'] : 'all';
  if (slug is! String || !['all', 'ris', 'aloe'].contains(slug)) {
    return const ValidateTrainerParamsResult.failure('Выберите слово из списка.');
  }
  return ValidateTrainerParamsResult.success({'wordSlug': slug});
}
