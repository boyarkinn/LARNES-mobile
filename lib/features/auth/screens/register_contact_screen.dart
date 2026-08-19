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
import 'package:larnes_mobile/features/auth/widgets/auth_contact_tabs.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_header.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_text_field.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_web_flow_shell.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

class RegisterContactScreen extends StatefulWidget {
  const RegisterContactScreen({super.key, required this.accountType});

  final RegisterAccountType accountType;

  @override
  State<RegisterContactScreen> createState() => _RegisterContactScreenState();
}

class _RegisterContactScreenState extends State<RegisterContactScreen> {
  RegisterContactChannel _channel = RegisterContactChannel.sms;
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
      final normalized = await AuthScope.of(context).registerApi.sendOtp(
        channel: _channel,
        contact: contact,
        locale: locale,
      );
      if (!mounted) {
        return;
      }

      final flow = RegisterFlowData(
        accountType: widget.accountType,
        contact: normalized,
        channel: _channel,
      );

      context.push(
        '/register/${widget.accountType.routeSlug}/otp',
        extra: flow,
      );
    } on RegisterApiException catch (error) {
      setState(() => _error = error.message);
    } catch (_) {
      setState(() => _error = l10n.requestFailed);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isPhone = _channel == RegisterContactChannel.sms;

    return AuthWebFlowShell(
      onBack: () => context.pop(),
      stepLabels: registerWizardStepLabels(context),
      currentStep: 1,
      stepTitle: l10n.registerContactStepTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_error != null) AuthErrorBanner(message: _error!),
          Text(
            l10n.registerWizardContactChannelLabel,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AuthColors.muted,
            ),
          ),
          const SizedBox(height: 8),
          AuthContactTabs<RegisterContactChannel>(
            value: _channel,
            options: [
              AuthContactTabOption(value: RegisterContactChannel.sms, label: l10n.phoneChannel),
              AuthContactTabOption(value: RegisterContactChannel.email, label: l10n.emailChannel),
            ],
            onChanged: (value) {
              setState(() {
                _channel = value;
                _error = null;
              });
            },
          ),
          const SizedBox(height: AuthMetrics.formGap),
          AuthInput(
            controller: _contactController,
            label: isPhone ? l10n.phoneLabel : l10n.emailLabel,
            keyboardType: isPhone ? TextInputType.phone : TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: AuthMetrics.formGap),
          AuthPrimaryButton(
            label: l10n.getCodeButton,
            isLoading: _isSubmitting,
            useWebAuthStyle: true,
            onPressed: _isSubmitting ? null : _continue,
          ),
        ],
      ),
    );
  }
}
