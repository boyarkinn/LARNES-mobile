import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:larnes_mobile/core/api/password_reset_api.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/auth/auth_flow_labels.dart';
import 'package:larnes_mobile/features/auth/theme/auth_theme.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_buttons.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_header.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_text_field.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_web_flow_shell.dart';
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

    return AuthWebFlowShell(
      onBack: () => context.pop(),
      stepLabels: passwordResetStepLabels(context),
      currentStep: 1,
      stepTitle: l10n.passwordResetContactStepTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.passwordResetContactHint,
            style: GoogleFonts.inter(
              fontSize: 14,
              height: 1.45,
              color: AuthColors.muted,
            ),
          ),
          const SizedBox(height: AuthMetrics.formGap),
          if (_error != null) AuthErrorBanner(message: _error!),
          AuthInput(
            controller: _contactController,
            label: l10n.passwordResetContactLabel,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.username],
          ),
          const SizedBox(height: AuthMetrics.formGap),
          AuthPrimaryButton(
            label: l10n.getCodeButton,
            isLoading: _isSubmitting,
            useWebAuthStyle: true,
            onPressed: _isSubmitting ? null : _continue,
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
