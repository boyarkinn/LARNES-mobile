import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';

/// Loading / error / terminal states for homework and program players.
/// Play HUD: [TrainerPlayShell] in `lib/trainers/runtime/`.
class ParentPlayerLoading extends StatelessWidget {
  const ParentPlayerLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: ParentColors.surface,
      body: Center(
        child: CircularProgressIndicator(color: ParentColors.shell),
      ),
    );
  }
}

class ParentPlayerState extends StatelessWidget {
  const ParentPlayerState({
    super.key,
    required this.actionLabel,
    required this.onAction,
    this.title,
    this.message,
  });

  final String? title;
  final String? message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ParentColors.surface,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title != null)
                  Text(
                    title!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.fredoka(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: ParentColors.ink,
                    ),
                  ),
                if (message != null) ...[
                  if (title != null) const SizedBox(height: 8),
                  Text(
                    message!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      color: ParentColors.inkMuted,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: ParentColors.shell,
                    minimumSize: const Size(0, 48),
                  ),
                  onPressed: onAction,
                  child: Text(actionLabel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ParentPlayerError extends StatelessWidget {
  const ParentPlayerError({
    super.key,
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ParentColors.surface,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: ParentColors.inkMuted),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: ParentColors.shell,
                  ),
                  onPressed: onRetry,
                  child: Text(retryLabel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
