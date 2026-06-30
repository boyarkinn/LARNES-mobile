import 'package:flutter/material.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';
import 'package:larnes_mobile/trainers/catalog/registry.dart';
import 'package:larnes_mobile/trainers/catalog/trainer_key.dart';
import 'package:larnes_mobile/trainers/runtime/unimplemented_trainer.dart';
import 'package:larnes_mobile/trainers/runtime/validate_params.dart';

class TrainerPlayer extends StatelessWidget {
  const TrainerPlayer({
    super.key,
    required this.trainerKey,
    required this.params,
    required this.l10n,
    this.onComplete,
  });

  final String trainerKey;
  final Map<String, dynamic> params;
  final AppLocalizations l10n;
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) {
    if (!isTrainerKey(trainerKey)) {
      return _TrainerPlayerError(
        message: 'Тренажёр «$trainerKey» не зарегистрирован.',
      );
    }

    final validated = validateTrainerParams(trainerKey, params);
    if (!validated.ok) {
      return _TrainerPlayerError(message: validated.error ?? l10n.requestError);
    }

    final key = TrainerKey.tryParse(trainerKey)!;
    final definition = trainerDefinitions[key]!;
    final validatedParams = validated.params!;

    final builder = trainerBuilders[key];
    if (builder != null) {
      return builder(params: validatedParams, onComplete: onComplete);
    }

    return UnimplementedTrainer(
      title: definition.title,
      trainerKey: trainerKey,
      l10n: l10n,
    );
  }
}

class _TrainerPlayerError extends StatelessWidget {
  const _TrainerPlayerError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Text(
        message,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFFB91C1C),
        ),
      ),
    );
  }
}

bool isTrainerInteractive(String trainerKey) {
  return getTrainerDefinition(trainerKey)?.isInteractive ?? false;
}
