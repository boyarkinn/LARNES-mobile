import 'package:flutter/material.dart';
import 'package:larnes_mobile/features/parent/models/parent_trainer_catalog.dart';
import 'package:larnes_mobile/features/parent/widgets/parent_scaffold.dart';
import 'package:larnes_mobile/features/parent/widgets/trainers/parent_trainer_run_panel.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

/// Параметры тренажёра — web `/parent/:childId/trainers/:direction/:trainerKey`.
class TrainerParamsScreen extends StatelessWidget {
  const TrainerParamsScreen({
    super.key,
    required this.childId,
    required this.direction,
    required this.trainerKey,
  });

  final String childId;
  final String direction;
  final String trainerKey;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (!isTrainerDirectionSlug(direction)) {
      return ParentScaffold(
        title: l10n.parentTrainersTitle,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              l10n.parentTrainersInvalidDirection,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return ParentScaffold(
      title: l10n.parentTrainersTitle,
      body: ParentTrainerRunPanel(
        childId: childId,
        direction: direction,
        trainerKey: trainerKey,
      ),
    );
  }
}
