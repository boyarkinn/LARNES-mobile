import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:larnes_mobile/core/api/parent_account_api.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_text_field.dart';
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
      _dateOfBirthController.text = AuthScope.of(context).user?.dateOfBirth ?? '';
    }
  }

  @override
  void dispose() {
    _dateOfBirthController.dispose();
    super.dispose();
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 30),
      firstDate: DateTime(1940),
      lastDate: now,
      locale: Localizations.localeOf(context),
    );
    if (picked != null) {
      final month = picked.month.toString().padLeft(2, '0');
      final day = picked.day.toString().padLeft(2, '0');
      _dateOfBirthController.text = '${picked.year}-$month-$day';
    }
  }

  Future<void> _submit() async {
    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final locale = LocaleScope.of(context).localeCode;
      final user = await AuthScope.of(context).parentAccountApi.updateDateOfBirth(
        dateOfBirth: _dateOfBirthController.text.trim(),
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
      backLabel: l10n.parentAccountBackToAccount,
      onBack: () => context.pop(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null) AuthErrorBanner(message: _error!),
            AuthTextField(
              controller: _dateOfBirthController,
              label: l10n.dateOfBirthLabel,
              readOnly: true,
              onTap: _pickDateOfBirth,
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
