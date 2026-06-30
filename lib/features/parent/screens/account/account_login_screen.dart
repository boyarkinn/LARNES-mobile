import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:larnes_mobile/core/api/parent_account_api.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_text_field.dart';
import 'package:larnes_mobile/features/parent/widgets/parent_scaffold.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

class AccountLoginScreen extends StatefulWidget {
  const AccountLoginScreen({super.key});

  @override
  State<AccountLoginScreen> createState() => _AccountLoginScreenState();
}

class _AccountLoginScreenState extends State<AccountLoginScreen> {
  final _currentPasswordController = TextEditingController();
  final _newLoginController = TextEditingController();
  final _confirmLoginController = TextEditingController();
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newLoginController.dispose();
    _confirmLoginController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final locale = LocaleScope.of(context).localeCode;
      final user = await AuthScope.of(context).parentAccountApi.updateLogin(
        currentPassword: _currentPasswordController.text,
        newLogin: _newLoginController.text.trim(),
        confirmNewLogin: _confirmLoginController.text.trim(),
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
      title: l10n.parentAccountLoginTitle,
      backLabel: l10n.parentAccountBackToAccount,
      onBack: () => context.pop(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null) AuthErrorBanner(message: _error!),
            AuthTextField(
              controller: _currentPasswordController,
              label: l10n.parentAccountCurrentPassword,
              obscureText: true,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            AuthTextField(
              controller: _newLoginController,
              label: l10n.parentAccountNewLogin,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            AuthTextField(
              controller: _confirmLoginController,
              label: l10n.parentAccountConfirmNewLogin,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(l10n.parentAccountSaveLogin),
            ),
          ],
        ),
      ),
    );
  }
}
