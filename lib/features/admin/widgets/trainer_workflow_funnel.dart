import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:larnes_mobile/app/theme/admin_theme.dart';
import 'package:larnes_mobile/features/admin/models/trainer_workflow.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';

class TrainerWorkflowFunnel extends StatelessWidget {
  const TrainerWorkflowFunnel({
    super.key,
    required this.status,
    required this.l10n,
  });

  final TrainerReleaseLifecycleStatus status;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final activeIndex = status == TrainerReleaseLifecycleStatus.readyForRelease ? 1 : 0;
    final steps = const [
      TrainerReleaseLifecycleStatus.inDevelopment,
      TrainerReleaseLifecycleStatus.readyForRelease,
    ];

    return Row(
      children: [
        for (var index = 0; index < steps.length; index++) ...[
          if (index > 0)
            Container(
              width: 16,
              height: 1,
              color: index <= activeIndex ? const Color(0xFFA5B4FC) : AdminColors.line,
            ),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: index <= activeIndex ? _activeBackground(steps[index]) : AdminColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: index <= activeIndex ? _activeBorder(steps[index]) : AdminColors.line,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                child: Text(
                  _label(l10n, steps[index]),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: index <= activeIndex ? _activeText(steps[index]) : AdminColors.inkMuted,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _label(AppLocalizations l10n, TrainerReleaseLifecycleStatus step) {
    switch (step) {
      case TrainerReleaseLifecycleStatus.readyForRelease:
        return l10n.adminTrainersStatusReadyForRelease;
      case TrainerReleaseLifecycleStatus.inDevelopment:
        return l10n.adminTrainersStatusInDevelopment;
    }
  }

  Color _activeBackground(TrainerReleaseLifecycleStatus step) {
    switch (step) {
      case TrainerReleaseLifecycleStatus.readyForRelease:
        return const Color(0xFFECFDF5);
      case TrainerReleaseLifecycleStatus.inDevelopment:
        return const Color(0xFFEEF2FF);
    }
  }

  Color _activeBorder(TrainerReleaseLifecycleStatus step) {
    switch (step) {
      case TrainerReleaseLifecycleStatus.readyForRelease:
        return const Color(0xFFA7F3D0);
      case TrainerReleaseLifecycleStatus.inDevelopment:
        return const Color(0xFFC7D2FE);
    }
  }

  Color _activeText(TrainerReleaseLifecycleStatus step) {
    switch (step) {
      case TrainerReleaseLifecycleStatus.readyForRelease:
        return const Color(0xFF065F46);
      case TrainerReleaseLifecycleStatus.inDevelopment:
        return const Color(0xFF3730A3);
    }
  }
}
