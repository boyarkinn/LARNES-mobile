import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:larnes_mobile/features/auth/models/register_flow.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_scaffold.dart';

class RegisterTypeScreen extends StatelessWidget {
  const RegisterTypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      showBackButton: true,
      onBack: () => context.go('/login'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AuthHeader(
            title: 'Регистрация',
            subtitle: 'Выберите тип аккаунта',
          ),
          for (final type in RegisterAccountType.values) ...[
            OutlinedButton(
              onPressed: () => context.push('/register/${type.routeSlug}/contact'),
              child: Text(type.label),
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => context.go('/login'),
            child: const Text('Уже есть аккаунт? Войти'),
          ),
        ],
      ),
    );
  }
}
