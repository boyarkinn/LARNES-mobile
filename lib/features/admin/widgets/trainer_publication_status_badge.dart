import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:larnes_mobile/features/admin/models/trainer_catalog.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';

class TrainerPublicationStatusBadge extends StatelessWidget {
  const TrainerPublicationStatusBadge({
    super.key,
    required this.status,
    required this.l10n,
  });

  final TrainerPublicationStatus status;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final colors = switch (status) {
      TrainerPublicationStatus.published => (
          background: const Color(0xFFECFDF5),
          text: const Color(0xFF047857),
        ),
      TrainerPublicationStatus.readyToPublish => (
          background: const Color(0xFFFFFBEB),
          text: const Color(0xFF92400E),
        ),
      TrainerPublicationStatus.inDevelopment => (
          background: const Color(0xFFEEF2FF),
          text: const Color(0xFF3730A3),
        ),
    };

    final label = switch (status) {
      TrainerPublicationStatus.published => l10n.adminTrainersPublicationPublished,
      TrainerPublicationStatus.readyToPublish => l10n.adminTrainersPublicationReadyToPublish,
      TrainerPublicationStatus.inDevelopment => l10n.adminTrainersPublicationInDevelopment,
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: colors.text,
          ),
        ),
      ),
    );
  }
}
