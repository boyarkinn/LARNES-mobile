import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:larnes_mobile/features/auth/models/register_flow.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_header.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_role_card.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_scaffold.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

class RegisterTypeScreen extends StatelessWidget {
  const RegisterTypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final types = RegisterAccountType.values;

    return AuthScaffold(
      variant: AuthScaffoldVariant.web,
      showBackButton: true,
      onBack: () => context.go('/login'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthCompactKicker(text: l10n.registerHubEyebrow),
          for (var index = 0; index < types.length; index++) ...[
            AuthRoleCard(
              accountType: types[index],
              onTap: () => context.push('/register/${types[index].routeSlug}/contact'),
            ),
            if (index < types.length - 1) const SizedBox(height: 10),
          ],
          AuthFormFoot(
            leadText: l10n.registerHasAccount,
            linkLabel: l10n.registerLoginLink,
            onLinkPressed: () => context.go('/login'),
          ),
        ],
      ),
    );
  }
}
