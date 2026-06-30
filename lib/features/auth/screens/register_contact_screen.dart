import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:larnes_mobile/features/auth/models/register_flow.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_scaffold.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_text_field.dart';

class RegisterContactScreen extends StatefulWidget {
  const RegisterContactScreen({super.key, required this.accountType});

  final RegisterAccountType accountType;

  @override
  State<RegisterContactScreen> createState() => _RegisterContactScreenState();
}

class _RegisterContactScreenState extends State<RegisterContactScreen> {
  RegisterContactChannel _channel = RegisterContactChannel.sms;
  final _contactController = TextEditingController();

  @override
  void dispose() {
    _contactController.dispose();
    super.dispose();
  }

  void _continue() {
    final contact = _contactController.text.trim();
    if (contact.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите контакт')),
      );
      return;
    }

    final flow = RegisterFlowData(
      accountType: widget.accountType,
      contact: contact,
      channel: _channel,
    );

    context.push(
      '/register/${widget.accountType.routeSlug}/otp',
      extra: flow,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = _channel == RegisterContactChannel.sms;

    return AuthScaffold(
      showBackButton: true,
      onBack: () => context.pop(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthHeader(
            title: widget.accountType.label,
            subtitle: 'Шаг 1 из 3 — подтверждение контакта',
          ),
          SegmentedButton<RegisterContactChannel>(
            segments: const [
              ButtonSegment(
                value: RegisterContactChannel.sms,
                label: Text('Телефон'),
              ),
              ButtonSegment(
                value: RegisterContactChannel.email,
                label: Text('Почта'),
              ),
            ],
            selected: {_channel},
            onSelectionChanged: (value) {
              setState(() => _channel = value.first);
            },
          ),
          const SizedBox(height: 16),
          AuthTextField(
            controller: _contactController,
            label: isPhone ? 'Телефон' : 'Email',
            keyboardType:
                isPhone ? TextInputType.phone : TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          const Text(
            'Здесь будет Turnstile и отправка кода (mobile API — следующий этап).',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _continue,
            child: const Text('Получить код'),
          ),
        ],
      ),
    );
  }
}
