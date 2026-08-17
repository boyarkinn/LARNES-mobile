import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:larnes_mobile/app/theme/admin_theme.dart';
import 'package:larnes_mobile/features/admin/models/trainer_catalog.dart';
import 'package:larnes_mobile/features/admin/widgets/trainer_publication_status_badge.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';

class TrainerCatalogCard extends StatelessWidget {
  const TrainerCatalogCard({
    super.key,
    required this.trainer,
    required this.l10n,
    required this.onOpen,
  });

  final TrainerCatalogItem trainer;
  final AppLocalizations l10n;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminColors.line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    trainer.title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AdminColors.ink,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TrainerPublicationStatusBadge(
                  status: trainer.publicationStatus,
                  l10n: l10n,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              trainer.key,
              style: GoogleFonts.robotoMono(
                fontSize: 12,
                color: AdminColors.inkMuted,
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AdminColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: onOpen,
                child: Text(l10n.adminTrainersOpen),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
