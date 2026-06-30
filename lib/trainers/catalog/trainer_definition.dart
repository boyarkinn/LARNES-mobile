import 'package:larnes_mobile/trainers/catalog/trainer_direction.dart';
import 'package:larnes_mobile/trainers/catalog/trainer_key.dart';
import 'package:larnes_mobile/trainers/catalog/validate_trainer_params_result.dart';

typedef TrainerParamsValidator = ValidateTrainerParamsResult Function(
  Map<String, dynamic> raw,
);

class TrainerDefinition {
  const TrainerDefinition({
    required this.key,
    required this.title,
    required this.direction,
    required this.validate,
    this.isInteractive = false,
  });

  final TrainerKey key;
  final String title;
  final TrainerDirection direction;
  final bool isInteractive;
  final TrainerParamsValidator validate;
}
