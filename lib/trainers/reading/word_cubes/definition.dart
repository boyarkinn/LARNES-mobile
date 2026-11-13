import 'package:larnes_mobile/trainers/catalog/validate_trainer_params_result.dart';
import '../shared/content_bank.dart';

ValidateTrainerParamsResult validateWordCubesParams(Map<String, dynamic> raw) {
  final error = validateReadingContentSelection(raw);
  if (error != null) return ValidateTrainerParamsResult.failure(error);
  return ValidateTrainerParamsResult.success({
    'contentBank': raw['contentBank'],
  });
}
