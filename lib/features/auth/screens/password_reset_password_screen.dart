import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:larnes_mobile/core/api/password_reset_api.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/core/routing/home_path_mapper.dart';
import 'package:larnes_mobile/features/auth/models/password_reset_flow.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_scaffold.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_text_field.dart';
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
      context.go(mapHomePathToMobile(homePath));
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

    return AuthScaffold(
      showBackButton: true,
      onBack: () => context.pop(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthHeader(
            title: l10n.passwordResetTitle,
            subtitle: l10n.passwordResetStep3Subtitle,
          ),
          Text(
            l10n.passwordResetPasswordHint,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          if (_error != null) AuthErrorBanner(message: _error!),
          AuthTextField(
            controller: _passwordController,
            label: l10n.passwordResetNewPasswordLabel,
            obscureText: true,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.newPassword],
          ),
          const SizedBox(height: 12),
          AuthTextField(
            controller: _passwordRepeatController,
            label: l10n.passwordResetConfirmPasswordLabel,
            obscureText: true,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.newPassword],
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _isSubmitting ? null : _submit,
            child: _isSubmitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.passwordResetSubmit),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => context.go('/login'),
            child: Text(l10n.passwordResetBackToLogin),
          ),
        ],
      ),
    );
  }
}
