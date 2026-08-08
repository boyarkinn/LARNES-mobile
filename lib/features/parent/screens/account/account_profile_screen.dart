import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:larnes_mobile/core/api/parent_account_api.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_text_field.dart';
import 'package:larnes_mobile/features/parent/widgets/account/desk_text_field.dart';
import 'package:larnes_mobile/features/parent/widgets/account/account_widgets.dart';
import 'package:larnes_mobile/features/parent/widgets/account/voluntary_consent_panel.dart';
import 'package:larnes_mobile/features/parent/widgets/parent_scaffold.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

class AccountProfileScreen extends StatefulWidget {
  const AccountProfileScreen({super.key});

  @override
  State<AccountProfileScreen> createState() => _AccountProfileScreenState();
}

class _AccountProfileScreenState extends State<AccountProfileScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _patronymicController = TextEditingController();
  bool _isSubmitting = false;
  String? _error;
  bool _initialized = false;
  VoluntaryConsentContext? _consentContext;
  bool _consentAccepted = false;
  final String _consentIdempotencyKey = newLegalIdempotencyKey();
  String _originalPatronymic = '';

  bool get _consentNeeded {
    final consent = _consentContext;
    final next = _patronymicController.text.trim();
    return consent != null &&
        !consent.isActive &&
        next.isNotEmpty &&
        next != _originalPatronymic;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final user = AuthScope.of(context).user;
      _firstNameController.text = user?.firstName ?? '';
      _lastNameController.text = user?.lastName ?? '';
      _patronymicController.text = user?.patronymic ?? '';
      _originalPatronymic = _patronymicController.text.trim();
      _patronymicController.addListener(_refreshConsentState);
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
    _firstNameController.dispose();
    _lastNameController.dispose();
    _patronymicController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
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
      final user = await AuthScope.of(context).parentAccountApi.updateProfile(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        patronymic: _patronymicController.text.trim(),
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
      title: l10n.parentAccountProfileTitle,
      body: AccountDeskFormShell(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null) AuthErrorBanner(message: _error!),
            DeskTextField(
              controller: _lastNameController,
              label: l10n.lastNameLabel,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            DeskTextField(
              controller: _firstNameController,
              label: l10n.firstNameLabel,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            DeskTextField(
              controller: _patronymicController,
              label: l10n.patronymicLabel,
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
