import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:larnes_mobile/app/theme/admin_theme.dart';
import 'package:larnes_mobile/features/admin/models/trainer_play.dart';
import 'package:larnes_mobile/features/admin/widgets/admin_account_scaffold.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';
import 'package:larnes_mobile/trainers/runtime/trainer_player.dart';

class AdminTrainerPlayScreen extends StatelessWidget {
  const AdminTrainerPlayScreen({super.key, required this.launch});

  final AdminTrainerPlayLaunch launch;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isInteractive = isTrainerInteractive(launch.trainerKey);

    return AdminAccountScaffold(
      title: launch.title,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: TrainerPlayer(
                  key: ValueKey('${launch.trainerKey}-${launch.params.hashCode}'),
                  trainerKey: launch.trainerKey,
                  params: launch.params,
                  l10n: l10n,
                  onComplete: isInteractive ? () => context.pop() : null,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isInteractive)
                  Text(
                    l10n.adminTrainerPlayInteractiveHint,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 13, color: AdminColors.inkMuted),
                  )
                else
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AdminColors.accent,
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: () => context.pop(),
                    child: Text(l10n.adminTrainerPlayContinueCheck),
                  ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => context.pop(),
                  child: Text(l10n.adminTrainerPlayExit),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
