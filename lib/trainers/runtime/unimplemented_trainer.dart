import 'package:flutter/material.dart';
import 'package:larnes_mobile/app/theme/larnes_theme.dart';
import 'package:larnes_mobile/features/parent/widgets/parent_scaffold.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';

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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: parentCardDecoration(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: LarnesColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            trainerKey,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: LarnesColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
            decoration: BoxDecoration(
              color: LarnesColors.skyTop,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: LarnesColors.border),
            ),
            child: Text(
              l10n.parentHomeworkPlayTrainerSoon,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: LarnesColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
