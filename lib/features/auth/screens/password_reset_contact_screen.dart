import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:larnes_mobile/core/api/password_reset_api.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_scaffold.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_text_field.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

class PasswordResetContactScreen extends StatefulWidget {
  const PasswordResetContactScreen({super.key});

  @override
  State<PasswordResetContactScreen> createState() =>
      _PasswordResetContactScreenState();
}

class _PasswordResetContactScreenState extends State<PasswordResetContactScreen> {
  final _contactController = TextEditingController();
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final l10n = context.l10n;
    final contact = _contactController.text.trim();
    if (contact.isEmpty) {
      setState(() => _error = l10n.enterContact);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final locale = LocaleScope.of(context).localeCode;
      final flow = await AuthScope.of(context).passwordResetApi.sendOtp(
        contact: contact,
        locale: locale,
      );
      if (!mounted) {
        return;
      }
      context.push('/password-reset/otp', extra: flow);
    } on PasswordResetApiException catch (error) {
      setState(() => _error = error.message);
    } catch (_) {
      setState(() => _error = l10n.sendCodeFailed);
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
            subtitle: l10n.passwordResetStep1Subtitle,
          ),
          Text(
            l10n.passwordResetContactHint,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          if (_error != null) AuthErrorBanner(message: _error!),
          AuthTextField(
            controller: _contactController,
            label: l10n.passwordResetContactLabel,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.username],
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _isSubmitting ? null : _continue,
            child: _isSubmitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.getCodeButton),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => context.go('/login'),
            child: Text(l10n.passwordResetBackToLogin),
          ),
        ],
      ),
    );
  }
}
