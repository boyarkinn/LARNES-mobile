import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:larnes_mobile/core/api/parent_api.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/config/app_config.dart';
import 'package:larnes_mobile/core/config/mobile_config.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/core/formatting/date_of_birth_input.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_text_field.dart';
import 'package:larnes_mobile/features/parent/widgets/account/desk_text_field.dart';
import 'package:larnes_mobile/features/auth/widgets/date_of_birth_text_field.dart';
import 'package:larnes_mobile/features/parent/models/parent_child.dart';
import 'package:larnes_mobile/features/parent/theme/child_card_colors.dart';
import 'package:larnes_mobile/features/parent/widgets/child_profile_appearance_fields.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';
import 'package:larnes_mobile/features/parent/widgets/parent_scaffold.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';
import 'package:share_plus/share_plus.dart';

String _childConsentUuid() {
  final bytes = List<int>.generate(16, (_) => Random.secure().nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes.map((value) => value.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

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
  String _authorityBasis = 'parent';
  ChildCardColor _cardColor = defaultChildCardColor;
  final String _childId = _childConsentUuid();
  final String _idempotencyKey = _childConsentUuid();
  MobileConfig? _config;
  bool _authorityDeclared = false;
  bool _consentAccepted = false;
  bool _isLoadingLegal = true;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLegalConfig();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _patronymicController.dispose();
    _dateOfBirthController.dispose();
    super.dispose();
  }

  Future<void> _loadLegalConfig() async {
    try {
      final locale = LocaleScope.of(context).localeCode;
      final config = await AuthScope.of(
        context,
      ).registerApi.fetchConfig(locale: locale);
      if (!mounted) return;
      setState(() {
        _config = config;
        _isLoadingLegal = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingLegal = false);
    }
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    final gender = _gender;
    if (gender == null) {
      setState(() => _error = l10n.parentChildFormGenderRequired);
      return;
    }

    if (!_authorityDeclared ||
        !_consentAccepted ||
        (_config?.childConsentVersionId.isEmpty ?? true)) {
      setState(() => _error = l10n.parentChildLegalRequired);
      return;
    }

    final dateOfBirth = displayDateToIso(_dateOfBirthController.text.trim());
    if (dateOfBirth == null) {
      setState(() => _error = l10n.invalidDateOfBirth);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final locale = LocaleScope.of(context).localeCode;
      final child = await AuthScope.of(context).parentApi.createChild(
        legal: ChildProfileLegalSubmission(
          authorityBasis: _authorityBasis,
          childId: _childId,
          documentVersionId: _config!.childConsentVersionId,
          idempotencyKey: _idempotencyKey,
        ),
        payload: CreateChildPayload(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          patronymic: _patronymicController.text.trim(),
          dateOfBirth: dateOfBirth,
          gender: gender,
          cardColor: _cardColor,
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
      title: l10n.parentAddChild,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null) AuthErrorBanner(message: _error!),
            DeskTextField(
              controller: _lastNameController,
              label: l10n.parentChildFormLastName,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            DeskTextField(
              controller: _firstNameController,
              label: l10n.parentChildFormFirstName,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            DeskTextField(
              controller: _patronymicController,
              label: l10n.parentChildFormPatronymic,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            DateOfBirthTextField(
              controller: _dateOfBirthController,
              label: l10n.parentChildFormDateOfBirth,
              textInputAction: TextInputAction.next,
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
            const SizedBox(height: 16),
            ChildProfileAppearanceFields(
              cardColor: _cardColor,
              onCardColorChanged: (color) => setState(() => _cardColor = color),
            ),
            const SizedBox(height: 20),
            Semantics(
              label: l10n.parentChildLegalBasisLabel,
              child: DropdownButtonFormField<String>(
              initialValue: _authorityBasis,
              decoration: const InputDecoration(),
              items: [
                DropdownMenuItem(
                  value: 'parent',
                  child: Text(l10n.parentChildLegalBasisParent),
                ),
                DropdownMenuItem(
                  value: 'adoptive_parent',
                  child: Text(l10n.parentChildLegalBasisAdoptiveParent),
                ),
                DropdownMenuItem(
                  value: 'appointed_guardian',
                  child: Text(l10n.parentChildLegalBasisGuardian),
                ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _authorityBasis = value);
              },
            ),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _authorityDeclared,
              onChanged: (value) =>
                  setState(() => _authorityDeclared = value ?? false),
              title: Text(l10n.parentChildLegalAuthority),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _consentAccepted,
              onChanged: (value) =>
                  setState(() => _consentAccepted = value ?? false),
              title: Text(l10n.parentChildLegalConsent),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: ParentColors.shell),
              onPressed: _config?.childConsentPath.isNotEmpty == true
                  ? () {
                      final base = AppConfig.apiBaseUrl.replaceFirst(RegExp(r'/$'), '');
                      SharePlus.instance.share(
                        ShareParams(text: '$base${_config!.childConsentPath}'),
                      );
                    }
                  : null,
              child: Text(l10n.parentChildLegalDocumentLink),
            ),
            const SizedBox(height: 24),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: ParentColors.shell,
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: _isSubmitting || _isLoadingLegal ? null : _submit,
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
