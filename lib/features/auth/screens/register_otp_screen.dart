import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:larnes_mobile/core/api/register_api.dart';
import 'package:larnes_mobile/core/auth/auth_session.dart';
import 'package:larnes_mobile/core/config/mobile_config.dart';
import 'package:larnes_mobile/features/auth/models/register_flow.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_scaffold.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_text_field.dart';
import 'package:larnes_mobile/features/auth/widgets/otp_input.dart';
import 'package:larnes_mobile/features/auth/widgets/turnstile_widget.dart';

class RegisterOtpScreen extends StatefulWidget {
  const RegisterOtpScreen({
    super.key,
    required this.flow,
    required this.authSession,
  });

  final RegisterFlowData flow;
  final AuthSession authSession;

  @override
  State<RegisterOtpScreen> createState() => _RegisterOtpScreenState();
}

class _RegisterOtpScreenState extends State<RegisterOtpScreen> {
  final _otpController = TextEditingController();
  MobileConfig? _config;
  String? _turnstileToken;
  int _turnstileResetKey = 0;
  bool _isSubmitting = false;
  bool _isResending = false;
  String? _error;
  String? _successMessage;
  int _secondsLeft = 60;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _startCooldown();
    _loadConfig();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    final config = await widget.authSession.registerApi.fetchConfig();
    if (mounted) {
      setState(() => _config = config);
    }
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _secondsLeft = 60);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft <= 1) {
        timer.cancel();
        if (mounted) {
          setState(() => _secondsLeft = 0);
        }
        return;
      }
      if (mounted) {
        setState(() => _secondsLeft -= 1);
      }
    });
  }

  Future<void> _continue() async {
    final code = _otpController.text.trim();
    if (code.length < 6) {
      setState(() => _error = 'Введите 6-значный код');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
      _successMessage = null;
    });

    try {
      final verificationToken = await widget.authSession.registerApi.verifyOtp(
        channel: widget.flow.channel,
        contact: widget.flow.contact,
        code: code,
      );
      if (!mounted) {
        return;
      }

      context.push(
        '/register/${widget.flow.accountType.routeSlug}/profile',
        extra: widget.flow.copyWith(verificationToken: verificationToken),
      );
    } on RegisterApiException catch (error) {
      setState(() => _error = error.message);
    } catch (_) {
      setState(() => _error = 'Не удалось проверить код.');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _resend() async {
    final config = _config ?? MobileConfig.fallback;
    if (config.turnstileRequired && (_turnstileToken == null || _turnstileToken!.isEmpty)) {
      setState(() => _error = 'Подтвердите, что вы не робот');
      return;
    }

    setState(() {
      _isResending = true;
      _error = null;
      _successMessage = null;
    });

    try {
      await widget.authSession.registerApi.resendOtp(
        channel: widget.flow.channel,
        contact: widget.flow.contact,
        turnstileToken: _turnstileToken,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _successMessage = 'Код отправлен снова';
        _turnstileToken = null;
        _turnstileResetKey += 1;
      });
      _startCooldown();
    } on RegisterApiException catch (error) {
      setState(() => _error = error.message);
    } catch (_) {
      setState(() => _error = 'Не удалось отправить код снова.');
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  String _maskContact(String contact) {
    if (widget.flow.channel == RegisterContactChannel.email) {
      final parts = contact.split('@');
      if (parts.length != 2 || parts[0].length < 2) {
        return contact;
      }
      return '${parts[0].substring(0, 2)}***@${parts[1]}';
    }
    if (contact.length < 6) {
      return contact;
    }
    return '${contact.substring(0, contact.length - 4)}****';
  }

  @override
  Widget build(BuildContext context) {
    final config = _config ?? MobileConfig.fallback;
    final canResend = _secondsLeft == 0 && !_isResending;

    return AuthScaffold(
      showBackButton: true,
      onBack: () => context.pop(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthHeader(
            title: 'Код подтверждения',
            subtitle: 'Отправили на ${_maskContact(widget.flow.contact)}',
          ),
          if (_error != null) AuthErrorBanner(message: _error!),
          if (_successMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _successMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
            ),
          OtpInput(controller: _otpController),
          const SizedBox(height: 12),
          if (canResend) ...[
            if (config.turnstileRequired && config.turnstileSiteKey.isNotEmpty) ...[
              TurnstileWidget(
                key: ValueKey(_turnstileResetKey),
                siteKey: config.turnstileSiteKey,
                resetKey: _turnstileResetKey,
                onTokenChanged: (token) => setState(() => _turnstileToken = token),
              ),
              const SizedBox(height: 8),
            ],
            TextButton(
              onPressed: _resend,
              child: const Text('Отправить код снова'),
            ),
          ] else
            Text(
              'Повторная отправка через $_secondsLeft с',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _isSubmitting ? null : _continue,
            child: _isSubmitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Продолжить'),
          ),
        ],
      ),
    );
  }
}
