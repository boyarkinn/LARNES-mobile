import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';
import 'package:larnes_mobile/core/api/parent_api.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/core/formatting/date_of_birth_input.dart';
import 'package:larnes_mobile/features/parent/widgets/account/desk_text_field.dart';
import 'package:larnes_mobile/features/auth/widgets/date_of_birth_text_field.dart';
import 'package:larnes_mobile/features/parent/models/parent_child.dart';
import 'package:larnes_mobile/features/parent/theme/child_avatar_catalog.dart';
import 'package:larnes_mobile/features/parent/theme/child_card_colors.dart';
import 'package:larnes_mobile/features/parent/utils/child_display.dart';
import 'package:larnes_mobile/features/parent/widgets/account/account_widgets.dart';
import 'package:larnes_mobile/features/parent/widgets/child_avatar.dart';
import 'package:larnes_mobile/features/parent/widgets/child_profile_appearance_fields.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

/// Inline edit form on child profile with debounced autosave (web `EditChildForm`).
class EditChildFormPanel extends StatefulWidget {
  const EditChildFormPanel({
    super.key,
    required this.childId,
    required this.initialChild,
    this.onSaved,
  });

  final String childId;
  final ParentChild initialChild;
  final ValueChanged<ParentChild>? onSaved;

  @override
  State<EditChildFormPanel> createState() => _EditChildFormPanelState();
}

class _EditChildFormPanelState extends State<EditChildFormPanel> {
  static const _autosaveDelay = Duration(milliseconds: 800);

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _patronymicController = TextEditingController();
  final _dateOfBirthController = TextEditingController();

  String? _gender;
  ChildCardColor _cardColor = defaultChildCardColor;
  ChildAvatarSlug _avatarSlug = defaultChildAvatarSlug;

  Timer? _debounce;
  bool _hydrating = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _hydrateFromChild(widget.initialChild);
    _firstNameController.addListener(_scheduleAutosave);
    _lastNameController.addListener(_scheduleAutosave);
    _patronymicController.addListener(_scheduleAutosave);
    _dateOfBirthController.addListener(_scheduleAutosave);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _hydrating = false);
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _patronymicController.dispose();
    _dateOfBirthController.dispose();
    super.dispose();
  }

  void _hydrateFromChild(ParentChild child) {
    _firstNameController.text = child.firstName;
    _lastNameController.text = child.lastName ?? '';
    _patronymicController.text = child.patronymic ?? '';
    _dateOfBirthController.text = isoDateToDisplay(child.dateOfBirth);
    _gender = child.gender;
    _cardColor = child.cardColor;
    _avatarSlug = child.avatarSlug;
  }

  void _scheduleAutosave() {
    if (_hydrating || _isSaving) {
      return;
    }
    _debounce?.cancel();
    _debounce = Timer(_autosaveDelay, _save);
  }

  void _notifyFieldChanged() {
    if (_hydrating) {
      return;
    }
    setState(() {});
    _scheduleAutosave();
  }

  bool _canSave() {
    final gender = _gender;
    return _lastNameController.text.trim().isNotEmpty &&
        _firstNameController.text.trim().isNotEmpty &&
        isCompleteDisplayDateOfBirth(_dateOfBirthController.text.trim()) &&
        (gender == 'male' || gender == 'female');
  }

  Future<void> _save() async {
    if (!_canSave() || _isSaving || !mounted) {
      return;
    }

    final l10n = context.l10n;
    setState(() => _isSaving = true);

    try {
      final locale = LocaleScope.of(context).localeCode;
      final dateOfBirth = displayDateToIso(_dateOfBirthController.text.trim());
      if (dateOfBirth == null) {
        return;
      }
      final updated = await AuthScope.of(context).parentApi.updateChild(
        childId: widget.childId,
        payload: CreateChildPayload(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          patronymic: _patronymicController.text.trim(),
          dateOfBirth: dateOfBirth,
          gender: _gender!,
          cardColor: _cardColor,
          avatarSlug: _avatarSlug,
        ),
        locale: locale,
      );

      if (!mounted) {
        return;
      }

      widget.onSaved?.call(updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.parentChildFormAutosaveSaved),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    } on ParentApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.parentChildFormAutosaveFailed),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String _headlineName() {
    final givenParts = [
      _firstNameController.text.trim(),
      _patronymicController.text.trim(),
    ].where((part) => part.isNotEmpty);
    final lastName = _lastNameController.text.trim();
    return '$lastName ${givenParts.join(' ')}'.trim();
  }

  int? _headlineAge(String localeCode) {
    final fromField = ageYearsFromIsoDate(_dateOfBirthController.text.trim());
    return fromField ?? widget.initialChild.ageYears;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final localeCode = LocaleScope.of(context).localeCode;
    final tokens = childCardColorTokens(_cardColor);
    final headlineAge = _headlineAge(localeCode);

    return ClipRRect(
      borderRadius: BorderRadius.circular(ParentRadii.card),
      child: DecoratedBox(
        decoration: parentCardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: AccountDeskMetrics.bandMinHeight,
              child: ColoredBox(color: tokens.tag),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
              child: Column(
                children: [
                  ChildAvatar(slug: _avatarSlug, size: 44),
                  const SizedBox(height: 10),
                  Text(
                    _headlineName(),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.fredoka(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                      color: ParentColors.ink,
                    ),
                  ),
                  if (headlineAge != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      formatChildAgeYears(headlineAge, localeCode),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: ParentColors.inkMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: AccountDeskMetrics.formPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
                  Text(l10n.parentChildFormGender, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: [
                      ButtonSegment(value: 'male', label: Text(l10n.parentChildFormGenderMale)),
                      ButtonSegment(value: 'female', label: Text(l10n.parentChildFormGenderFemale)),
                    ],
                    selected: _gender == null ? {} : {_gender!},
                    onSelectionChanged: (value) {
                      setState(() => _gender = value.first);
                      _scheduleAutosave();
                    },
                  ),
                  const SizedBox(height: 16),
                  ChildProfileAppearanceFields(
                    cardColor: _cardColor,
                    avatarSlug: _avatarSlug,
                    onCardColorChanged: (color) {
                      setState(() => _cardColor = color);
                      _scheduleAutosave();
                    },
                    onAvatarSlugChanged: (slug) {
                      setState(() => _avatarSlug = slug);
                      _scheduleAutosave();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

int? ageYearsFromIsoDate(String? iso) {
  final dob = parseDateOfBirthInput(iso);
  if (dob == null) {
    return null;
  }
  final now = DateTime.now();
  var age = now.year - dob.year;
  if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
    age--;
  }
  return age;
}
