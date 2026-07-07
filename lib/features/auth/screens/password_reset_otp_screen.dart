import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:larnes_mobile/core/api/password_reset_api.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/auth/models/password_reset_flow.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_buttons.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_scaffold.dart';
import 'package:larnes_mobile/features/auth/widgets/otp_input.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_text_field.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

class PasswordResetOtpScreen extends StatefulWidget {
  const PasswordResetOtpScreen({super.key, required this.flow});

  final PasswordResetFlowData flow;

  @override
  State<PasswordResetOtpScreen> createState() => _PasswordResetOtpScreenState();
}

class _PasswordResetOtpScreenState extends State<PasswordResetOtpScreen> {
  final _otpController = TextEditingController();
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
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _otpController.dispose();
    super.dispose();
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

  String _maskContact(String contact) {
    if (widget.flow.channel == PasswordResetChannel.email) {
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
      final verificationToken =
          await AuthScope.of(context).passwordResetApi.verifyOtp(
        contact: widget.flow.contact,
        code: code,
        locale: locale,
      );
      if (!mounted) {
        return;
      }
      context.push(
        '/password-reset/password',
        extra: widget.flow.copyWith(verificationToken: verificationToken),
      );
    } on PasswordResetApiException catch (error) {
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

    setState(() {
      _isResending = true;
      _error = null;
      _successMessage = null;
    });

    try {
      final locale = LocaleScope.of(context).localeCode;
      await AuthScope.of(context).passwordResetApi.resendOtp(
        contact: widget.flow.contact,
        locale: locale,
      );
      if (!mounted) {
        return;
      }
      setState(() => _successMessage = l10n.passwordResetOtpResent);
      _startCooldown();
    } on PasswordResetApiException catch (error) {
      setState(() => _error = error.message);
    } catch (_) {
      setState(() => _error = l10n.resendFailed);
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final canResend = _secondsLeft == 0 && !_isResending;
    final maskedContact = _maskContact(widget.flow.contact);
    final subtitle = widget.flow.channel == PasswordResetChannel.email
        ? l10n.passwordResetOtpHintEmail(maskedContact)
        : l10n.passwordResetOtpHintSms(maskedContact);

    return AuthScaffold(
      title: l10n.otpTitle,
      showBackButton: true,
      onBack: () => context.pop(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthBodyHint(text: subtitle),
          if (_error != null) AuthErrorBanner(message: _error!),
          if (_successMessage != null) AuthSuccessBanner(message: _successMessage!),
          OtpInput(controller: _otpController),
          const SizedBox(height: 12),
          if (canResend)
            AuthTextLink(
              label: l10n.resendCode,
              onPressed: _resend,
            )
          else
            AuthMutedText(text: l10n.resendCooldown(_secondsLeft)),
          const SizedBox(height: 16),
          AuthPrimaryButton(
            label: l10n.continueButton,
            isLoading: _isSubmitting,
            onPressed: _isSubmitting ? null : _continue,
          ),
          const SizedBox(height: 8),
          AuthTextLink(
            label: l10n.passwordResetBackToLogin,
            onPressed: () => context.go('/login'),
          ),
        ],
      ),
    );
  }
}
