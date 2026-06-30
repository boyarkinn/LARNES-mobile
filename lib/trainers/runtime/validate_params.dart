import 'package:larnes_mobile/trainers/catalog/registry.dart';
import 'package:larnes_mobile/trainers/catalog/trainer_key.dart';
import 'package:larnes_mobile/trainers/catalog/validate_trainer_params_result.dart';

ValidateTrainerParamsResult validateTrainerParams(
  String trainerKey,
  Map<String, dynamic> rawParams,
) {
  final key = TrainerKey.tryParse(trainerKey);
  if (key == null) {
    return ValidateTrainerParamsResult.failure(
      'Тренажёр «$trainerKey» не найден.',
    );
  }

  return trainerDefinitions[key]!.validate(rawParams);
}
