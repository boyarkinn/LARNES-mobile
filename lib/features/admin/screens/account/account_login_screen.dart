import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:larnes_mobile/core/api/admin_account_api.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/admin/widgets/admin_account_scaffold.dart';
import 'package:larnes_mobile/features/admin/widgets/admin_account_widgets.dart';
import 'package:larnes_mobile/features/admin/widgets/admin_text_field.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_text_field.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

class AdminAccountLoginScreen extends StatefulWidget {
  const AdminAccountLoginScreen({super.key});

  @override
  State<AdminAccountLoginScreen> createState() => _AdminAccountLoginScreenState();
}

class _AdminAccountLoginScreenState extends State<AdminAccountLoginScreen> {
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
      final user = await AuthScope.of(context).adminAccountApi.updateLogin(
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
    } on AdminAccountApiException catch (error) {
      setState(() => _error = error.message);
    } catch (_) {
      setState(() => _error = context.l10n.adminAccountSaveFailed);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AdminAccountScaffold(
      title: l10n.adminAccountLoginTitle,
      body: AdminAccountFormShell(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null) AuthErrorBanner(message: _error!),
            AdminTextField(
              controller: _currentPasswordController,
              label: l10n.parentAccountCurrentPassword,
              obscureText: true,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            AdminTextField(
              controller: _newLoginController,
              label: l10n.parentAccountNewLogin,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            AdminTextField(
              controller: _confirmLoginController,
              label: l10n.parentAccountConfirmNewLogin,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 24),
            AdminAccountPrimaryButton(
              label: l10n.adminAccountSaveLogin,
              isLoading: _isSubmitting,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
