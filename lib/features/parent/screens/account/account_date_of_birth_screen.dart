import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:larnes_mobile/core/api/parent_account_api.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/formatting/date_of_birth_input.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_text_field.dart';
import 'package:larnes_mobile/features/auth/widgets/date_of_birth_text_field.dart';
import 'package:larnes_mobile/features/parent/widgets/account/account_widgets.dart';
import 'package:larnes_mobile/features/parent/widgets/account/voluntary_consent_panel.dart';
import 'package:larnes_mobile/features/parent/widgets/parent_scaffold.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

class AccountDateOfBirthScreen extends StatefulWidget {
  const AccountDateOfBirthScreen({super.key});

  @override
  State<AccountDateOfBirthScreen> createState() => _AccountDateOfBirthScreenState();
}

class _AccountDateOfBirthScreenState extends State<AccountDateOfBirthScreen> {
  final _dateOfBirthController = TextEditingController();
  bool _isSubmitting = false;
  String? _error;
  bool _initialized = false;
  VoluntaryConsentContext? _consentContext;
  bool _consentAccepted = false;
  final String _consentIdempotencyKey = newLegalIdempotencyKey();
  String _originalIso = '';

  bool get _consentNeeded {
    final consent = _consentContext;
    final text = _dateOfBirthController.text.trim();
    final next = text.isEmpty ? '' : displayDateToIso(text) ?? '';
    return consent != null &&
        !consent.isActive &&
        next.isNotEmpty &&
        next != _originalIso;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _dateOfBirthController.text = isoDateToDisplay(
        AuthScope.of(context).user?.dateOfBirth,
      );
      _originalIso = AuthScope.of(context).user?.dateOfBirth ?? '';
      _dateOfBirthController.addListener(_refreshConsentState);
      _loadConsent();
    }
  }

  void _refreshConsentState() {
    if (mounted) setState(() {});
  }

  Future<void> _loadConsent() async {
    try {
      final locale = LocaleScope.of(context).localeCode;
      final snapshot = await AuthScope.of(context).parentAccountApi.fetchAccount(
        locale: locale,
      );
      if (mounted) setState(() => _consentContext = snapshot.voluntaryConsent);
    } catch (_) {
      // The save endpoint remains fail-closed if consent is required.
    }
  }

  @override
  void dispose() {
    _dateOfBirthController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _dateOfBirthController.text.trim();
    final iso = text.isEmpty ? '' : displayDateToIso(text);
    if (iso == null) {
      setState(() => _error = context.l10n.invalidDateOfBirth);
      return;
    }
    final consentContext = _consentContext;
    if (_consentNeeded &&
        (!_consentAccepted || consentContext?.versionId == null)) {
      setState(() => _error = context.l10n.voluntaryConsentRequired);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final locale = LocaleScope.of(context).localeCode;
      final user = await AuthScope.of(context).parentAccountApi.updateDateOfBirth(
        dateOfBirth: iso,
        consent: _consentNeeded
            ? VoluntaryConsentSubmission(
                accepted: true,
                idempotencyKey: _consentIdempotencyKey,
                versionId: consentContext!.versionId!,
              )
            : null,
        locale: locale,
      );
      if (!mounted) {
        return;
      }
      AuthScope.of(context).applyUser(user);
      context.pop();
    } on ParentAccountApiException catch (error) {
      setState(() => _error = error.message);
    } catch (_) {
      setState(() => _error = context.l10n.parentAccountSaveFailed);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return ParentScaffold(
      title: l10n.parentAccountDateOfBirthTitle,
      body: AccountDeskFormShell(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null) AuthErrorBanner(message: _error!),
            DateOfBirthTextField(
              controller: _dateOfBirthController,
              label: l10n.dateOfBirthLabel,
              textInputAction: TextInputAction.done,
            ),
            if (_consentNeeded && _consentContext != null) ...[
              const SizedBox(height: 16),
              VoluntaryConsentPanel(
                accepted: _consentAccepted,
                context: _consentContext!,
                onChanged: (value) => setState(() => _consentAccepted = value),
              ),
            ],
            const SizedBox(height: 24),
            AccountPrimaryButton(
              label: l10n.parentAccountSave,
              isLoading: _isSubmitting,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
