import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';

class UnimplementedTrainer extends StatelessWidget {
  const UnimplementedTrainer({
    super.key,
    required this.title,
    required this.trainerKey,
    required this.l10n,
  });

  final String title;
  final String trainerKey;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return TrainerScene(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.fredoka(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: ParentColors.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                trainerKey,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: ParentColors.inkMuted,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.parentHomeworkPlayTrainerSoon,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: ParentColors.inkMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
