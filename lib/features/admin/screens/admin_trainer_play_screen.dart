import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:larnes_mobile/features/admin/models/trainer_play.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';
import 'package:larnes_mobile/trainers/runtime/trainer_play_shell.dart';
import 'package:larnes_mobile/trainers/runtime/trainer_play_theme.dart';
import 'package:larnes_mobile/trainers/runtime/trainer_player.dart';
import 'package:larnes_mobile/trainers/runtime/trainer_step_chrome.dart';

class AdminTrainerPlayScreen extends StatelessWidget {
  const AdminTrainerPlayScreen({super.key, required this.launch});

  final AdminTrainerPlayLaunch launch;

  void _exit(BuildContext context) {
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isInteractive = isTrainerInteractive(launch.trainerKey);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        _exit(context);
      },
      child: TrainerPlayShell(
        currentStep: 1,
        totalSteps: 1,
        theme: TrainerPlayTheme.admin,
        menuContinueLabel: l10n.adminTrainerPlayMenuContinue,
        menuExitLabel: l10n.adminTrainerPlayExit,
        onExit: () => _exit(context),
        child: TrainerPlayer(
          key: ValueKey('${launch.trainerKey}-${launch.params.hashCode}'),
          trainerKey: launch.trainerKey,
          params: launch.params,
          l10n: l10n,
          onComplete: isInteractive ? () => _exit(context) : null,
          stepChrome: TrainerStepChrome(
            finishLabel: l10n.adminTrainerPlayFinish,
            isInteractive: isInteractive,
            isLast: true,
            nextLabel: l10n.adminTrainerPlayNext,
            onAdvance: () => _exit(context),
            theme: TrainerPlayTheme.admin,
          ),
        ),
      ),
    );
  }
}
