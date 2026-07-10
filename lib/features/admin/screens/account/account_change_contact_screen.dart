import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:larnes_mobile/app/theme/admin_theme.dart';
import 'package:larnes_mobile/core/api/admin_account_api.dart';
import 'package:larnes_mobile/core/api/parent_account_api.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/admin/widgets/admin_account_scaffold.dart';
import 'package:larnes_mobile/features/admin/widgets/admin_account_widgets.dart';
import 'package:larnes_mobile/features/admin/widgets/admin_text_field.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_text_field.dart';
import 'package:larnes_mobile/features/auth/widgets/otp_input.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

enum AdminAccountContactChangeChannel { phone, email }

class AdminAccountChangeContactScreen extends StatefulWidget {
  const AdminAccountChangeContactScreen({super.key, required this.channel});

  final AdminAccountContactChangeChannel channel;

  @override
  State<AdminAccountChangeContactScreen> createState() => _AdminAccountChangeContactScreenState();
}

class _AdminAccountChangeContactScreenState extends State<AdminAccountChangeContactScreen> {
  final _currentPasswordController = TextEditingController();
  final _contactController = TextEditingController();
  final _otpController = TextEditingController();

  bool _isSubmitting = false;
  bool _isResending = false;
  String? _error;
  String? _successMessage;
  int _secondsLeft = 0;
  Timer? _cooldownTimer;

  String? _pendingContact;
  String? _pendingToken;
  bool _otpStep = false;

  ContactChangeChannel get _apiChannel =>
      widget.channel == AdminAccountContactChangeChannel.phone
          ? ContactChangeChannel.phone
          : ContactChangeChannel.email;

  bool get _isPhone => widget.channel == AdminAccountContactChangeChannel.phone;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _currentPasswordController.dispose();
    _contactController.dispose();
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

  Future<void> _sendCode() async {
    final l10n = context.l10n;
    final contact = _contactController.text.trim();
    if (contact.isEmpty) {
      setState(() => _error = l10n.enterContact);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
      _successMessage = null;
    });

    try {
      final locale = LocaleScope.of(context).localeCode;
      final result = await AuthScope.of(context).adminAccountApi.sendContactChangeOtp(
        channel: _apiChannel,
        currentPassword: _currentPasswordController.text,
        newContact: contact,
        locale: locale,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _otpStep = true;
        _pendingContact = result.contact;
        _pendingToken = result.pendingToken;
      });
      _startCooldown();
    } on AdminAccountApiException catch (error) {
      setState(() => _error = error.message);
    } catch (_) {
      setState(() => _error = l10n.sendCodeFailed);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _verifyCode() async {
    final l10n = context.l10n;
    final code = _otpController.text.trim();
    final pendingToken = _pendingToken;
    if (code.length < 6 || pendingToken == null || pendingToken.isEmpty) {
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
      final user = await AuthScope.of(context).adminAccountApi.verifyContactChangeOtp(
        channel: _apiChannel,
        pendingToken: pendingToken,
        code: code,
        locale: locale,
      );
      if (!mounted) {
        return;
      }
      AuthScope.of(context).applyUser(user);
      context.pop();
    } on AdminAccountApiException catch (error) {
      setState(() => _error = error.message);
    } catch (_) {
      setState(() => _error = l10n.verifyCodeFailed);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _resendCode() async {
    final l10n = context.l10n;
    final pendingToken = _pendingToken;
    if (pendingToken == null || pendingToken.isEmpty) {
      setState(() => _error = l10n.verifyCodeFailed);
      return;
    }

    setState(() {
      _isResending = true;
      _error = null;
      _successMessage = null;
    });

    try {
      final locale = LocaleScope.of(context).localeCode;
      await AuthScope.of(context).adminAccountApi.resendContactChangeOtp(
        channel: _apiChannel,
        pendingToken: pendingToken,
        locale: locale,
      );
      if (!mounted) {
        return;
      }
      setState(() => _successMessage = l10n.codeResent);
      _startCooldown();
    } on AdminAccountApiException catch (error) {
      setState(() => _error = error.message);
    } catch (_) {
      setState(() => _error = l10n.resendFailed);
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  void _backToForm() {
    _cooldownTimer?.cancel();
    setState(() {
      _otpStep = false;
      _pendingContact = null;
      _pendingToken = null;
      _otpController.clear();
      _error = null;
      _successMessage = null;
      _secondsLeft = 0;
    });
  }

  String _maskContact(String contact) {
    if (!_isPhone) {
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
    final title = _isPhone ? l10n.adminAccountPhoneTitle : l10n.adminAccountEmailTitle;
    final canResend = _secondsLeft == 0 && !_isResending;

    return PopScope(
      canPop: !_otpStep,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _otpStep) {
          _backToForm();
        }
      },
      child: AdminAccountScaffold(
        title: title,
        body: AdminAccountFormShell(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null) AuthErrorBanner(message: _error!),
              if (_successMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _successMessage!,
                    style: const TextStyle(color: AdminColors.accent),
                  ),
                ),
              if (!_otpStep) ...[
                AdminTextField(
                  controller: _currentPasswordController,
                  label: l10n.parentAccountCurrentPassword,
                  obscureText: true,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                AdminTextField(
                  controller: _contactController,
                  label: _isPhone ? l10n.parentAccountNewPhone : l10n.parentAccountNewEmail,
                  keyboardType: _isPhone ? TextInputType.phone : TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 24),
                AdminAccountPrimaryButton(
                  label: l10n.parentAccountSendCode,
                  isLoading: _isSubmitting,
                  onPressed: _sendCode,
                ),
              ] else ...[
                Text(
                  l10n.otpSentTo(_maskContact(_pendingContact ?? '')),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                OtpInput(controller: _otpController),
                const SizedBox(height: 12),
                if (canResend)
                  TextButton(
                    onPressed: _resendCode,
                    child: Text(l10n.resendCode),
                  )
                else
                  Text(
                    l10n.resendCooldown(_secondsLeft),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: AdminColors.inkMuted),
                  ),
                const SizedBox(height: 12),
                AdminAccountPrimaryButton(
                  label: l10n.parentAccountVerifyContact,
                  isLoading: _isSubmitting,
                  onPressed: _verifyCode,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
