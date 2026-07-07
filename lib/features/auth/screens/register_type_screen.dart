import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';
import 'package:larnes_mobile/features/auth/models/register_flow.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_buttons.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_register_type_card.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_scaffold.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

class RegisterTypeScreen extends StatelessWidget {
  const RegisterTypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final types = RegisterAccountType.values;

    return AuthScaffold(
      title: l10n.registerTitle,
      showBackButton: true,
      onBack: () => context.go('/login'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < types.length; index++) ...[
            AuthRegisterTypeCard(
              title: types[index].label(context),
              subtitle: types[index].description(context),
              tokens: types[index].cardTokens,
              icon: types[index].cardIcon,
              onTap: () => context.push('/register/${types[index].routeSlug}/contact'),
            ),
            if (index < types.length - 1)
              const SizedBox(height: ParentChildCardMetrics.pickerListGap),
          ],
          const SizedBox(height: 24),
          AuthTextLink(
            label: l10n.alreadyHaveAccount,
            onPressed: () => context.go('/login'),
          ),
        ],
      ),
    );
  }
}
