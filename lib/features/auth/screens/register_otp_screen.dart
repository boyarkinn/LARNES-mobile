import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:larnes_mobile/features/auth/models/register_flow.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_scaffold.dart';
import 'package:larnes_mobile/features/auth/widgets/otp_input.dart';

class RegisterOtpScreen extends StatefulWidget {
  const RegisterOtpScreen({super.key, required this.flow});

  final RegisterFlowData flow;

  @override
  State<RegisterOtpScreen> createState() => _RegisterOtpScreenState();
}

class _RegisterOtpScreenState extends State<RegisterOtpScreen> {
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _continue() {
    if (_otpController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите 6-значный код')),
      );
      return;
    }

    context.push(
      '/register/${widget.flow.accountType.routeSlug}/profile',
      extra: widget.flow,
    );
  }

  @override
  Widget build(BuildContext context) {
    final masked = widget.flow.contact;

    return AuthScaffold(
      showBackButton: true,
      onBack: () => context.pop(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthHeader(
            title: 'Код подтверждения',
            subtitle: 'Отправили на $masked',
          ),
          OtpInput(controller: _otpController),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Resend OTP — следующий этап')),
              );
            },
            child: const Text('Отправить код снова'),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _continue,
            child: const Text('Продолжить'),
          ),
        ],
      ),
    );
  }
}
