import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/api/register_api.dart';
import 'package:larnes_mobile/core/config/mobile_config.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/auth/models/register_flow.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_scaffold.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_text_field.dart';
import 'package:larnes_mobile/features/auth/widgets/otp_input.dart';
import 'package:larnes_mobile/features/auth/widgets/turnstile_widget.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

class RegisterOtpScreen extends StatefulWidget {
  const RegisterOtpScreen({super.key, required this.flow});

  final RegisterFlowData flow;

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
    final config = await AuthScope.of(context).registerApi.fetchConfig();
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
    final l10n = context.l10n;
    final code = _otpController.text.trim();
    if (code.length < 6) {
      setState(() => _error = l10n.enterSixDigitCode);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
      _successMessage = null;
    });

    try {
      final locale = LocaleScope.of(context).localeCode;
      final verificationToken = await AuthScope.of(context).registerApi.verifyOtp(
        channel: widget.flow.channel,
        contact: widget.flow.contact,
        code: code,
        locale: locale,
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
      setState(() => _error = l10n.verifyCodeFailed);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _resend() async {
    final l10n = context.l10n;
    final config = _config ?? MobileConfig.fallback;
    if (config.turnstileRequired && (_turnstileToken == null || _turnstileToken!.isEmpty)) {
      setState(() => _error = l10n.confirmNotRobot);
      return;
    }

    setState(() {
      _isResending = true;
      _error = null;
      _successMessage = null;
    });

    try {
      final locale = LocaleScope.of(context).localeCode;
      await AuthScope.of(context).registerApi.resendOtp(
        channel: widget.flow.channel,
        contact: widget.flow.contact,
        turnstileToken: _turnstileToken,
        locale: locale,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _successMessage = l10n.codeResent;
        _turnstileToken = null;
        _turnstileResetKey += 1;
      });
      _startCooldown();
    } on RegisterApiException catch (error) {
      setState(() => _error = error.message);
      _resetTurnstileAfterFailedResend(config);
    } catch (_) {
      setState(() => _error = l10n.resendFailed);
      _resetTurnstileAfterFailedResend(config);
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  void _resetTurnstileAfterFailedResend(MobileConfig config) {
    if (!config.turnstileRequired) {
      return;
    }
    setState(() {
      _turnstileToken = null;
      _turnstileResetKey += 1;
    });
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
    final l10n = context.l10n;
    final config = _config ?? MobileConfig.fallback;
    final canResend = _secondsLeft == 0 && !_isResending;

    return AuthScaffold(
      showBackButton: true,
      onBack: () => context.pop(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthHeader(
            title: l10n.otpTitle,
            subtitle: l10n.otpSentTo(_maskContact(widget.flow.contact)),
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
            if (config.turnstileRequired && config.turnstilePageUrl.isNotEmpty) ...[
              TurnstileWidget(
                key: ValueKey('turnstile-resend-$_turnstileResetKey'),
                pageUrl: config.turnstilePageUrl,
                resetKey: _turnstileResetKey,
                onTokenChanged: (token) => setState(() => _turnstileToken = token),
              ),
              const SizedBox(height: 8),
            ],
            TextButton(
              onPressed: _resend,
              child: Text(l10n.resendCode),
            ),
          ] else
            Text(
              l10n.resendCooldown(_secondsLeft),
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
                : Text(l10n.continueButton),
          ),
        ],
      ),
    );
  }
}
