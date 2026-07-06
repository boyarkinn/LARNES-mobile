import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';

/// Player shell homework/programs (Morning Desk v4).
/// Эталон: platform `.parent-player-*`
class ParentPlayerShell extends StatelessWidget {
  const ParentPlayerShell({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.exitLabel,
    required this.onExit,
    required this.body,
    this.footer,
    this.showExitButton = true,
  });

  final String eyebrow;
  final String title;
  final String exitLabel;
  final VoidCallback onExit;
  final Widget body;
  final Widget? footer;
  final bool showExitButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ParentColors.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          eyebrow,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.06 * 11,
                            color: ParentColors.inkMuted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          title,
                          style: GoogleFonts.fredoka(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                            color: ParentColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (showExitButton)
                    TextButton(
                      onPressed: onExit,
                      style: TextButton.styleFrom(
                        foregroundColor: ParentColors.inkMuted,
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: Text(exitLabel),
                    ),
                ],
              ),
            ),
            const Divider(height: 1, color: ParentColors.line),
            Expanded(child: body),
            if (footer != null) ...[
              const Divider(height: 1, color: ParentColors.line),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                child: footer!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

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
