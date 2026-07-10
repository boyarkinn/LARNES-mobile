import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

/// Dead-end guard: retry, family-setup CTA, logout — не оставлять пользователя в ловушке.
class ParentPanelErrorPanel extends StatelessWidget {
  const ParentPanelErrorPanel({
    super.key,
    required this.message,
    required this.onRetry,
    this.showFamilySetupAction = false,
    this.onFamilySetup,
  });

  final String message;
  final VoidCallback onRetry;
  final bool showFamilySetupAction;
  final VoidCallback? onFamilySetup;

  Future<void> _logout(BuildContext context) async {
    await AuthScope.of(context).logout();
    if (context.mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Center(
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
            if (showFamilySetupAction && onFamilySetup != null) ...[
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: ParentColors.shell),
                onPressed: onFamilySetup,
                child: Text(l10n.parentFamilySetupContinueAction),
              ),
              const SizedBox(height: 8),
            ],
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: showFamilySetupAction ? ParentColors.parchmentDeep : ParentColors.shell,
                foregroundColor: showFamilySetupAction ? ParentColors.shell : null,
              ),
              onPressed: onRetry,
              child: Text(l10n.continueButton),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => _logout(context),
              child: Text(l10n.logoutButton),
            ),
          ],
        ),
      ),
    );
  }
}
