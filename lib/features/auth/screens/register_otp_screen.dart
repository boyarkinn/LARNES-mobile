import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/api/register_api.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/auth/auth_flow_labels.dart';
import 'package:larnes_mobile/features/auth/models/register_flow.dart';
import 'package:larnes_mobile/features/auth/theme/auth_theme.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_buttons.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_header.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_text_field.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_web_flow_shell.dart';
import 'package:larnes_mobile/features/auth/widgets/otp_input.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

class RegisterOtpScreen extends StatefulWidget {
  const RegisterOtpScreen({super.key, required this.flow});

  final RegisterFlowData flow;

  @override
  State<RegisterOtpScreen> createState() => _RegisterOtpScreenState();
}

class _RegisterOtpScreenState extends State<RegisterOtpScreen> {
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

      final nextFlow = widget.flow.copyWith(verificationToken: verificationToken);
      if (widget.flow.accountType == RegisterAccountType.parent) {
        context.push(
          '/register/parent/school-offers',
          extra: nextFlow,
        );
      } else {
        context.push(
          '/register/${widget.flow.accountType.routeSlug}/profile',
          extra: nextFlow,
        );
      }
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
        locale: locale,
      );
      if (!mounted) {
        return;
      }
      setState(() => _successMessage = l10n.codeResent);
      _startCooldown();
    } on RegisterApiException catch (error) {
      setState(() => _error = error.message);
    } catch (_) {
      setState(() => _error = l10n.resendFailed);
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
    final l10n = context.l10n;
    final canResend = _secondsLeft == 0 && !_isResending;

    return AuthWebFlowShell(
      onBack: () => context.pop(),
      stepLabels: registerWizardStepLabels(context),
      currentStep: 2,
      stepTitle: l10n.registerOtpStepTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.otpSentTo(_maskContact(widget.flow.contact)),
            style: GoogleFonts.inter(
              fontSize: 14,
              height: 1.45,
              color: AuthColors.muted,
            ),
          ),
          const SizedBox(height: AuthMetrics.formGap),
          if (_error != null) AuthErrorBanner(message: _error!),
          if (_successMessage != null) AuthSuccessBanner(message: _successMessage!),
          OtpInput(controller: _otpController, useWebAuthStyle: true),
          const SizedBox(height: 12),
          if (canResend)
            AuthTextLink(
              label: l10n.resendCode,
              useWebAuthStyle: true,
              onPressed: _resend,
            )
          else
            Text(
              l10n.resendCooldown(_secondsLeft),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AuthColors.muted,
              ),
            ),
          const SizedBox(height: AuthMetrics.formGap),
          AuthPrimaryButton(
            label: l10n.registerWizardOtpSubmit,
            isLoading: _isSubmitting,
            useWebAuthStyle: true,
            onPressed: _isSubmitting ? null : _continue,
          ),
          const SizedBox(height: 8),
          AuthTextLink(
            label: l10n.registerWizardOtpBack,
            useWebAuthStyle: true,
            onPressed: () => context.pop(),
          ),
        ],
      ),
    );
  }
}
