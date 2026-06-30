import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:larnes_mobile/features/auth/models/register_flow.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_scaffold.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

class RegisterTypeScreen extends StatelessWidget {
  const RegisterTypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AuthScaffold(
      showBackButton: true,
      onBack: () => context.go('/login'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthHeader(
            title: l10n.registerTitle,
            subtitle: l10n.registerSubtitle,
          ),
          for (final type in RegisterAccountType.values) ...[
            OutlinedButton(
              onPressed: () => context.push('/register/${type.routeSlug}/contact'),
              child: Text(type.label(context)),
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => context.go('/login'),
            child: Text(l10n.alreadyHaveAccount),
          ),
        ],
      ),
    );
  }
}
