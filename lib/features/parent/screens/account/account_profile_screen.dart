import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:larnes_mobile/core/api/parent_account_api.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_text_field.dart';
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final user = AuthScope.of(context).user;
      _firstNameController.text = user?.firstName ?? '';
      _lastNameController.text = user?.lastName ?? '';
      _patronymicController.text = user?.patronymic ?? '';
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
      backLabel: l10n.parentAccountBackToAccount,
      onBack: () => context.pop(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null) AuthErrorBanner(message: _error!),
            AuthTextField(
              controller: _lastNameController,
              label: l10n.lastNameLabel,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            AuthTextField(
              controller: _firstNameController,
              label: l10n.firstNameLabel,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            AuthTextField(
              controller: _patronymicController,
              label: l10n.patronymicLabel,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(l10n.parentAccountSave),
            ),
          ],
        ),
      ),
    );
  }
}
