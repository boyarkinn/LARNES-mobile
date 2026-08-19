import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:larnes_mobile/core/api/password_reset_api.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/core/routing/home_path_mapper.dart';
import 'package:larnes_mobile/features/auth/auth_flow_labels.dart';
import 'package:larnes_mobile/features/auth/models/password_reset_flow.dart';
import 'package:larnes_mobile/features/auth/theme/auth_theme.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_buttons.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_header.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_text_field.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_web_flow_shell.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

class PasswordResetPasswordScreen extends StatefulWidget {
  const PasswordResetPasswordScreen({super.key, required this.flow});

  final PasswordResetFlowData flow;

  @override
  State<PasswordResetPasswordScreen> createState() =>
      _PasswordResetPasswordScreenState();
}

class _PasswordResetPasswordScreenState extends State<PasswordResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _passwordRepeatController = TextEditingController();
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    _passwordRepeatController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = context.l10n;

    if (widget.flow.verificationToken.isEmpty) {
      setState(() => _error = l10n.verifyContactFirst);
      return;
    }

    if (_passwordController.text != _passwordRepeatController.text) {
      setState(() => _error = l10n.passwordsDoNotMatch);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final locale = LocaleScope.of(context).localeCode;
      final result = await AuthScope.of(context).passwordResetApi.setPassword(
        verificationToken: widget.flow.verificationToken,
        password: _passwordController.text,
        confirmPassword: _passwordRepeatController.text,
        locale: locale,
      );
      if (!mounted) {
        return;
      }
      final homePath = await AuthScope.of(context).completeRegistration(result);
      if (!mounted) {
        return;
      }
      context.go(
        resolvePostAuthDestination(
          accountType: AuthScope.of(context).user?.accountType,
          homePath: homePath,
          familySetupComplete: AuthScope.of(context).familySetupComplete,
        ),
      );
    } on PasswordResetApiException catch (error) {
      setState(() => _error = error.message);
    } catch (_) {
      setState(() => _error = l10n.passwordResetFailed);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AuthWebFlowShell(
      onBack: () => context.pop(),
      stepLabels: passwordResetStepLabels(context),
      currentStep: 3,
      stepTitle: l10n.passwordResetPasswordStepTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.passwordResetPasswordHint,
            style: GoogleFonts.inter(
              fontSize: 14,
              height: 1.45,
              color: AuthColors.muted,
            ),
          ),
          const SizedBox(height: AuthMetrics.formGap),
          if (_error != null) AuthErrorBanner(message: _error!),
          AuthInput(
            controller: _passwordController,
            label: l10n.passwordResetNewPasswordLabel,
            obscureText: true,
            enablePasswordToggle: true,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.newPassword],
          ),
          const SizedBox(height: AuthMetrics.formGap),
          AuthInput(
            controller: _passwordRepeatController,
            label: l10n.passwordResetConfirmPasswordLabel,
            obscureText: true,
            enablePasswordToggle: true,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.newPassword],
            onSubmitted: (_) => _isSubmitting ? null : _submit(),
          ),
          const SizedBox(height: AuthMetrics.formGap),
          AuthPrimaryButton(
            label: l10n.passwordResetSubmit,
            isLoading: _isSubmitting,
            useWebAuthStyle: true,
            onPressed: _isSubmitting ? null : _submit,
          ),
          const SizedBox(height: 8),
          AuthTextLink(
            label: l10n.passwordResetBackToLogin,
            useWebAuthStyle: true,
            onPressed: () => context.go('/login'),
          ),
        ],
      ),
    );
  }
}
