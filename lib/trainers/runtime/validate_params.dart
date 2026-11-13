import 'package:larnes_mobile/trainers/catalog/registry.dart';
import 'package:larnes_mobile/trainers/catalog/trainer_key.dart';
import 'package:larnes_mobile/trainers/catalog/validate_trainer_params_result.dart';
import 'package:larnes_mobile/trainers/reading/shared/content_bank.dart';

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

  final result = trainerDefinitions[key]!.validate(rawParams);
  if (!result.ok || result.params == null) return result;
  return ValidateTrainerParamsResult.success({
    ...result.params!,
    if (usesReadingContentBank(trainerKey) && rawParams['contentBank'] is Map)
      'contentBank': rawParams['contentBank'],
    if (rawParams['__runtimeSnapshot'] != null)
      '__runtimeSnapshot': rawParams['__runtimeSnapshot'],
  });
}
