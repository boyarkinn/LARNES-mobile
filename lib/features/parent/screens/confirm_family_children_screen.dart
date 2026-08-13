import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';
import 'package:larnes_mobile/core/api/confirm_family_children_api.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/formatting/date_of_birth_input.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/auth/widgets/date_of_birth_text_field.dart';
import 'package:larnes_mobile/features/parent/widgets/account/account_widgets.dart';
import 'package:larnes_mobile/features/parent/widgets/account/desk_text_field.dart';
import 'package:larnes_mobile/features/parent/widgets/parent_scaffold.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

String _uuid() {
  final bytes = List<int>.generate(16, (_) => Random.secure().nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes.map((v) => v.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

class ConfirmFamilyChildrenScreen extends StatefulWidget {
  const ConfirmFamilyChildrenScreen({super.key});

  @override
  State<ConfirmFamilyChildrenScreen> createState() => _ConfirmFamilyChildrenScreenState();
}

class _ConfirmFamilyChildrenScreenState extends State<ConfirmFamilyChildrenScreen> {
  bool _isLoading = true;
  bool _isPending = false;
  String? _error;
  PendingConfirmFamily? _pending;
  final _controllers = <String, _ChildControllers>{};
  bool _authorityDeclared = false;
  bool _consentAccepted = false;
  String _authorityBasis = 'parent';
  final _idempotencyKey = _uuid();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _load();
      }
    });
  }

  @override
  void dispose() {
    for (final entry in _controllers.values) {
      entry.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final locale = LocaleScope.read(context).localeCode;
      final pending = await AuthScope.of(context).confirmFamilyChildrenApi.fetchPending(
            locale: locale,
          );
      if (!mounted) {
        return;
      }
      if (pending == null) {
        context.go('/parent');
        return;
      }
      for (final child in pending.children) {
        _controllers[child.id] = _ChildControllers.fromChild(child);
      }
      setState(() {
        _pending = pending;
        _isLoading = false;
      });
    } on ConfirmFamilyChildrenApiException catch (error) {
      if (mounted) {
        setState(() {
          _error = error.message;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = context.l10n.requestFailed;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _submit() async {
    final pending = _pending;
    if (pending == null) {
      return;
    }
    final l10n = context.l10n;

    final children = <ConfirmFamilyChildDraft>[];
    for (final child in pending.children) {
      final c = _controllers[child.id]!;
      final dob = displayDateToIso(c.dateOfBirth.text.trim());
      if (dob == null || c.gender == null) {
        setState(() => _error = l10n.invalidDateOfBirth);
        return;
      }
      children.add(
        ConfirmFamilyChildDraft(
          id: child.id,
          firstName: c.firstName.text.trim(),
          lastName: c.lastName.text.trim(),
          patronymic: c.patronymic.text.trim(),
          dateOfBirth: dob,
          gender: c.gender,
        ),
      );
    }

    if (children.isNotEmpty && (!_authorityDeclared || !_consentAccepted)) {
      setState(() => _error = l10n.parentConfirmFamilyChildrenConsentRequired);
      return;
    }

    setState(() {
      _isPending = true;
      _error = null;
    });

    try {
      final locale = LocaleScope.of(context).localeCode;
      await AuthScope.of(context).confirmFamilyChildrenApi.confirm(
            familyId: pending.familyId,
            documentVersionId: pending.childDataConsentVersionId,
            idempotencyKey: _idempotencyKey,
            children: children,
            authorityBasis: _authorityBasis,
            authorityDeclared: _authorityDeclared,
            consentAccepted: _consentAccepted,
            locale: locale,
          );
      if (!mounted) {
        return;
      }
      AuthScope.of(context).notifyParentDataChanged();
      context.go('/parent');
    } on ConfirmFamilyChildrenApiException catch (error) {
      if (mounted) {
        setState(() {
          _error = error.message;
          _isPending = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = context.l10n.requestFailed;
          _isPending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final pending = _pending;

    return ParentScaffold(
      title: l10n.parentConfirmFamilyChildrenTitle,
      showBack: false,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : AccountDeskShell(
              children: [
                AccountDeskCard(
                  child: Padding(
                    padding: AccountDeskMetrics.formPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l10n.parentConfirmFamilyChildrenSubtitle(
                            pending?.familyDisplayName ?? '',
                          ),
                          style: GoogleFonts.onest(
                            fontSize: 14,
                            color: ParentColors.inkMuted,
                            height: 1.45,
                          ),
                        ),
                        if (pending != null && pending.children.isEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            l10n.parentConfirmFamilyChildrenNoChildren,
                            style: GoogleFonts.onest(fontSize: 14, color: ParentColors.ink),
                          ),
                        ],
                        if (pending != null)
                          for (final child in pending.children) ...[
                            const SizedBox(height: 16),
                            Text(
                              child.displayName ?? child.firstName,
                              style: GoogleFonts.fredoka(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: ParentColors.ink,
                              ),
                            ),
                            const SizedBox(height: 8),
                            DeskTextField(
                              controller: _controllers[child.id]!.lastName,
                              label: l10n.lastNameLabel,
                            ),
                            DeskTextField(
                              controller: _controllers[child.id]!.firstName,
                              label: l10n.firstNameLabel,
                            ),
                            DeskTextField(
                              controller: _controllers[child.id]!.patronymic,
                              label: l10n.patronymicLabel,
                            ),
                            DateOfBirthTextField(
                              controller: _controllers[child.id]!.dateOfBirth,
                              label: l10n.dateOfBirthLabel,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.parentConfirmFamilyChildrenGender,
                              style: GoogleFonts.onest(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: ParentColors.inkMuted,
                              ),
                            ),
                            DropdownButtonFormField<String>(
                              value: _controllers[child.id]!.gender,
                              decoration: DeskTextField.inputDecoration(),
                              items: [
                                DropdownMenuItem(
                                  value: 'male',
                                  child: Text(l10n.parentConfirmFamilyChildrenGenderMale),
                                ),
                                DropdownMenuItem(
                                  value: 'female',
                                  child: Text(l10n.parentConfirmFamilyChildrenGenderFemale),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() => _controllers[child.id]!.gender = value);
                              },
                            ),
                          ],
                        if (pending != null && pending.children.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            l10n.parentConfirmFamilyChildrenAuthority,
                            style: GoogleFonts.onest(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: ParentColors.inkMuted,
                            ),
                          ),
                          DropdownButtonFormField<String>(
                            value: _authorityBasis,
                            decoration: DeskTextField.inputDecoration(),
                            items: [
                              DropdownMenuItem(
                                value: 'parent',
                                child: Text(l10n.parentConfirmFamilyChildrenAuthorityParent),
                              ),
                              DropdownMenuItem(
                                value: 'adoptive_parent',
                                child: Text(l10n.parentConfirmFamilyChildrenAuthorityAdoptive),
                              ),
                              DropdownMenuItem(
                                value: 'appointed_guardian',
                                child: Text(l10n.parentConfirmFamilyChildrenAuthorityGuardian),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _authorityBasis = value);
                              }
                            },
                          ),
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            value: _authorityDeclared,
                            onChanged: (v) => setState(() => _authorityDeclared = v ?? false),
                            title: Text(l10n.parentConfirmFamilyChildrenAuthorityDeclared),
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            value: _consentAccepted,
                            onChanged: (v) => setState(() => _consentAccepted = v ?? false),
                            title: Text(l10n.parentConfirmFamilyChildrenConsentAccepted),
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                        ],
                        if (_error != null) ...[
                          const SizedBox(height: 8),
                          Text(_error!, style: const TextStyle(color: Color(0xFFB91C1C))),
                        ],
                        const SizedBox(height: 16),
                        AccountPrimaryButton(
                          label: l10n.parentConfirmFamilyChildrenSubmit,
                          isLoading: _isPending,
                          onPressed: _submit,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _ChildControllers {
  _ChildControllers({
    required this.firstName,
    required this.lastName,
    required this.patronymic,
    required this.dateOfBirth,
    this.gender,
  });

  factory _ChildControllers.fromChild(ConfirmFamilyChildDraft child) {
    final iso = child.dateOfBirth;
    String displayDob = '';
    if (iso != null && iso.contains('-')) {
      final parts = iso.split('-');
      if (parts.length == 3) {
        displayDob = '${parts[2]}.${parts[1]}.${parts[0]}';
      }
    }
    return _ChildControllers(
      firstName: TextEditingController(text: child.firstName),
      lastName: TextEditingController(text: child.lastName ?? ''),
      patronymic: TextEditingController(text: child.patronymic ?? ''),
      dateOfBirth: TextEditingController(text: displayDob),
      gender: child.gender,
    );
  }

  final TextEditingController firstName;
  final TextEditingController lastName;
  final TextEditingController patronymic;
  final TextEditingController dateOfBirth;
  String? gender;

  void dispose() {
    firstName.dispose();
    lastName.dispose();
    patronymic.dispose();
    dateOfBirth.dispose();
  }
}
