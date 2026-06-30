import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:larnes_mobile/features/auth/models/register_flow.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_scaffold.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_text_field.dart';

class RegisterProfileScreen extends StatefulWidget {
  const RegisterProfileScreen({super.key, required this.flow});

  final RegisterFlowData flow;

  @override
  State<RegisterProfileScreen> createState() => _RegisterProfileScreenState();
}

class _RegisterProfileScreenState extends State<RegisterProfileScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordRepeatController = TextEditingController();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _passwordController.dispose();
    _passwordRepeatController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_passwordController.text != _passwordRepeatController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пароли не совпадают')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Регистрация на сервере — следующий этап (mobile API)'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      showBackButton: true,
      onBack: () => context.pop(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthHeader(
            title: 'Профиль',
            subtitle: 'Шаг 3 из 3 — ${widget.flow.accountType.label}',
          ),
          AuthTextField(
            controller: _firstNameController,
            label: 'Имя',
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          AuthTextField(
            controller: _lastNameController,
            label: 'Фамилия',
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          AuthTextField(
            controller: _passwordController,
            label: 'Пароль',
            obscureText: true,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          AuthTextField(
            controller: _passwordRepeatController,
            label: 'Повторите пароль',
            obscureText: true,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _submit,
            child: const Text('Создать аккаунт'),
          ),
        ],
      ),
    );
  }
}
