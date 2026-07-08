import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:larnes_mobile/core/api/parent_account_api.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_text_field.dart';
import 'package:larnes_mobile/features/parent/widgets/account/account_widgets.dart';
import 'package:larnes_mobile/features/parent/widgets/parent_scaffold.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

class AccountRelationshipScreen extends StatefulWidget {
  const AccountRelationshipScreen({
    super.key,
    this.initialRelationship,
  });

  final String? initialRelationship;

  @override
  State<AccountRelationshipScreen> createState() => _AccountRelationshipScreenState();
}

class _AccountRelationshipScreenState extends State<AccountRelationshipScreen> {
  String? _selectedRelationship;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedRelationship = widget.initialRelationship ?? 'mother';
  }

  Future<void> _submit() async {
    final relationship = _selectedRelationship;
    if (relationship == null) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final locale = LocaleScope.of(context).localeCode;
      await AuthScope.of(context).parentAccountApi.updateRelationship(
        relationship: relationship,
        locale: locale,
      );
      if (!mounted) {
        return;
      }
      AuthScope.of(context).notifyParentDataChanged();
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
      title: l10n.parentAccountRelationshipTitle,
      body: AccountDeskFormShell(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null) AuthErrorBanner(message: _error!),
            DropdownMenu<String>(
              initialSelection: _selectedRelationship,
              label: Text(l10n.parentAccountFieldRelationship),
              dropdownMenuEntries: [
                DropdownMenuEntry(
                  value: 'mother',
                  label: l10n.parentGuardiansRelationshipMother,
                ),
                DropdownMenuEntry(
                  value: 'father',
                  label: l10n.parentGuardiansRelationshipFather,
                ),
                DropdownMenuEntry(
                  value: 'grandmother',
                  label: l10n.parentGuardiansRelationshipGrandmother,
                ),
                DropdownMenuEntry(
                  value: 'grandfather',
                  label: l10n.parentGuardiansRelationshipGrandfather,
                ),
              ],
              onSelected: (value) => setState(() => _selectedRelationship = value),
            ),
            const SizedBox(height: 24),
            AccountPrimaryButton(
              label: l10n.parentAccountSaveRelationship,
              isLoading: _isSubmitting,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
