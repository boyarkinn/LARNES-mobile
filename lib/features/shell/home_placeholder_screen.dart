import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:larnes_mobile/core/auth/auth_session.dart';
import 'package:larnes_mobile/features/auth/widgets/language_switcher.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

class HomePlaceholderScreen extends StatelessWidget {
  const HomePlaceholderScreen({super.key, required this.authSession});

  final AuthSession authSession;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final user = authSession.user;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          const LanguageSwitcher(),
          TextButton(
            onPressed: () async {
              await authSession.logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
            child: Text(l10n.logoutButton),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.loggedInTitle,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            Text(l10n.nameValue(user?.displayName ?? l10n.emptyValue)),
            Text(l10n.roleValue(user?.accountType ?? l10n.emptyValue)),
            const SizedBox(height: 24),
            Text(l10n.homePlaceholder),
          ],
        ),
      ),
    );
  }
}
