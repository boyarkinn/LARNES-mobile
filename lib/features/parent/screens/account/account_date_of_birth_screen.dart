import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:larnes_mobile/core/api/parent_account_api.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/formatting/date_of_birth_input.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_text_field.dart';
import 'package:larnes_mobile/features/auth/widgets/date_of_birth_text_field.dart';
import 'package:larnes_mobile/features/parent/widgets/account/account_widgets.dart';
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _dateOfBirthController.text = isoDateToDisplay(
        AuthScope.of(context).user?.dateOfBirth,
      );
    }
  }

  @override
  void dispose() {
    _dateOfBirthController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final iso = displayDateToIso(_dateOfBirthController.text.trim());
    if (iso == null) {
      setState(() => _error = context.l10n.invalidDateOfBirth);
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
