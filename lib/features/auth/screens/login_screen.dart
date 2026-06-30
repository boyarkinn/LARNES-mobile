import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:larnes_mobile/core/api/auth_api.dart';
import 'package:larnes_mobile/core/auth/auth_session.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_scaffold.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.authSession});

  final AuthSession authSession;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final homePath = await widget.authSession.login(
        login: _loginController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) {
        return;
      }
      context.go(_mapHomePath(homePath));
    } on AuthApiException catch (error) {
      setState(() => _error = error.message);
    } catch (_) {
      setState(() => _error = 'Не удалось войти. Попробуйте позже.');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String _mapHomePath(String webPath) {
    if (webPath.startsWith('/teacher')) {
      return '/home';
    }
    if (webPath.startsWith('/network')) {
      return '/home';
    }
    return '/home';
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AuthHeader(
            title: 'Вход',
            subtitle: 'Телефон, email или логин и пароль',
          ),
          if (_error != null) AuthErrorBanner(message: _error!),
          AuthTextField(
            controller: _loginController,
            label: 'Телефон, email или логин',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.username],
          ),
          const SizedBox(height: 12),
          AuthTextField(
            controller: _passwordController,
            label: 'Пароль',
            obscureText: true,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Сброс пароля — в следующем этапе')),
                );
              },
              child: const Text('Забыли пароль?'),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _isSubmitting ? null : _submit,
            child: _isSubmitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Войти'),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => context.push('/register'),
            child: const Text('Нет аккаунта? Зарегистрироваться'),
          ),
        ],
      ),
    );
  }
}
