import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:larnes_mobile/core/api/parent_api.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_text_field.dart';
import 'package:larnes_mobile/features/parent/models/parent_child.dart';
import 'package:larnes_mobile/features/parent/widgets/parent_scaffold.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

class AddChildScreen extends StatefulWidget {
  const AddChildScreen({super.key});

  @override
  State<AddChildScreen> createState() => _AddChildScreenState();
}

class _AddChildScreenState extends State<AddChildScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _patronymicController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  String? _gender;
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _patronymicController.dispose();
    _dateOfBirthController.dispose();
    super.dispose();
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 7),
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
    final l10n = context.l10n;
    final gender = _gender;
    if (gender == null) {
      setState(() => _error = l10n.parentChildFormGenderRequired);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final locale = LocaleScope.of(context).localeCode;
      final child = await AuthScope.of(context).parentApi.createChild(
        payload: CreateChildPayload(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          patronymic: _patronymicController.text.trim(),
          dateOfBirth: _dateOfBirthController.text.trim(),
          gender: gender,
        ),
        locale: locale,
      );
      if (!mounted) {
        return;
      }
      context.pop(child.id);
    } on ParentApiException catch (error) {
      setState(() => _error = error.message);
    } catch (_) {
      setState(() => _error = l10n.parentCreateChildFailed);
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
      title: l10n.parentChildFormTitle,
      backLabel: l10n.parentBack,
      onBack: () => context.pop(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null) AuthErrorBanner(message: _error!),
            AuthTextField(
              controller: _lastNameController,
              label: l10n.parentChildFormLastName,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            AuthTextField(
              controller: _firstNameController,
              label: l10n.parentChildFormFirstName,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            AuthTextField(
              controller: _patronymicController,
              label: l10n.parentChildFormPatronymic,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            AuthTextField(
              controller: _dateOfBirthController,
              label: l10n.parentChildFormDateOfBirth,
              readOnly: true,
              onTap: _pickDateOfBirth,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.parentChildFormGender,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              emptySelectionAllowed: true,
              segments: [
                ButtonSegment(value: 'male', label: Text(l10n.parentChildFormGenderMale)),
                ButtonSegment(value: 'female', label: Text(l10n.parentChildFormGenderFemale)),
              ],
              selected: _gender == null ? {} : {_gender!},
              onSelectionChanged: (value) {
                setState(() {
                  _gender = value.isEmpty ? null : value.first;
                  _error = null;
                });
              },
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.parentChildFormSubmit),
            ),
          ],
        ),
      ),
    );
  }
}
