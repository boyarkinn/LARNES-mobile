import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:larnes_mobile/core/auth/auth_session.dart';

class HomePlaceholderScreen extends StatelessWidget {
  const HomePlaceholderScreen({super.key, required this.authSession});

  final AuthSession authSession;

  @override
  Widget build(BuildContext context) {
    final user = authSession.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('LARNES'),
        actions: [
          TextButton(
            onPressed: () async {
              await authSession.logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
            child: const Text('Выйти'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Вы вошли',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            Text('Имя: ${user?.displayName ?? '—'}'),
            Text('Роль: ${user?.accountType ?? '—'}'),
            const SizedBox(height: 24),
            const Text(
              'Здесь будет панель по роли (родитель / учитель / сеть).',
            ),
          ],
        ),
      ),
    );
  }
}
