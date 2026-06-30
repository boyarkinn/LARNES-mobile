import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:larnes_mobile/core/api/parent_account_api.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_text_field.dart';
import 'package:larnes_mobile/features/parent/widgets/parent_scaffold.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

class AccountPasswordScreen extends StatefulWidget {
  const AccountPasswordScreen({super.key});

  @override
  State<AccountPasswordScreen> createState() => _AccountPasswordScreenState();
}

class _AccountPasswordScreenState extends State<AccountPasswordScreen> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() => _error = l10n.passwordsDoNotMatch);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final locale = LocaleScope.of(context).localeCode;
      final auth = AuthScope.of(context);
      final result = await auth.parentAccountApi.updatePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
        confirmNewPassword: _confirmPasswordController.text,
        locale: locale,
      );
      if (!mounted) {
        return;
      }
      if (result.token != null && result.token!.isNotEmpty) {
        await auth.persistToken(result.token!);
      }
      auth.applyUser(result.user);
      context.pop();
    } on ParentAccountApiException catch (error) {
      setState(() => _error = error.message);
    } catch (_) {
      setState(() => _error = l10n.parentAccountSaveFailed);
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
      title: l10n.parentAccountPasswordTitle,
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
              controller: _newPasswordController,
              label: l10n.parentAccountNewPassword,
              obscureText: true,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            AuthTextField(
              controller: _confirmPasswordController,
              label: l10n.parentAccountConfirmNewPassword,
              obscureText: true,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(l10n.parentAccountSavePassword),
            ),
          ],
        ),
      ),
    );
  }
}
