import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:larnes_mobile/app/theme/admin_theme.dart';
import 'package:larnes_mobile/features/admin/models/trainer_catalog.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';

class TrainerReleaseStatusBadge extends StatelessWidget {
  const TrainerReleaseStatusBadge({
    super.key,
    required this.platformLabel,
    required this.status,
    required this.l10n,
  });

  final String platformLabel;
  final TrainerReleaseStatus status;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final isReady = status == TrainerReleaseStatus.readyForRelease;
    final colors = isReady
        ? (
            background: const Color(0xFFECFDF5),
            text: const Color(0xFF047857),
          )
        : (
            background: const Color(0xFFEEF2FF),
            text: const Color(0xFF3730A3),
          );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          platformLabel,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: AdminColors.inkMuted,
          ),
        ),
        const SizedBox(width: 4),
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.background,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            child: Text(
              isReady
                  ? l10n.adminTrainersStatusReadyForRelease
                  : l10n.adminTrainersStatusInDevelopment,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: colors.text,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
