import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';
import 'package:larnes_mobile/core/routing/home_path_mapper.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/api/register_api.dart';
import 'package:larnes_mobile/core/api/register_school_offers_api.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/auth/auth_flow_labels.dart';
import 'package:larnes_mobile/features/auth/models/register_flow.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_buttons.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_header.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_web_flow_shell.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_text_field.dart';
import 'package:larnes_mobile/core/formatting/date_of_birth_input.dart';
import 'package:larnes_mobile/features/auth/widgets/date_of_birth_text_field.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';
import 'package:larnes_mobile/core/config/app_config.dart';
import 'package:larnes_mobile/core/config/mobile_config.dart';
import 'package:larnes_mobile/core/api/places_api.dart';
import 'package:larnes_mobile/core/widgets/place_autocomplete_field.dart';
import 'package:share_plus/share_plus.dart';

String _registrationUuid() {
  final bytes = List<int>.generate(16, (_) => Random.secure().nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes.map((value) => value.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

class RegisterProfileScreen extends StatefulWidget {
  const RegisterProfileScreen({super.key, required this.flow});

  final RegisterFlowData flow;

  @override
  State<RegisterProfileScreen> createState() => _RegisterProfileScreenState();
}

class _RegisterProfileScreenState extends State<RegisterProfileScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _patronymicController = TextEditingController();
  final _networkNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordRepeatController = TextEditingController();
  final _dateOfBirthController = TextEditingController();

  String? _selectedRelationship = 'mother';
  PlaceCitySelection? _citySelection;
  bool _isLoadingConfig = true;
  bool _isSubmitting = false;
  bool _termsAccepted = false;
  MobileConfig? _config;
  final String _idempotencyKey = _registrationUuid();
  String? _error;

  bool _authorityDeclared = false;
  bool _consentAccepted = false;

  @override
  void initState() {
    super.initState();
    if (widget.flow.accountType == RegisterAccountType.networkOwner &&
        widget.flow.channel == RegisterContactChannel.email) {
      _emailController.text = widget.flow.contact;
    }
    if (widget.flow.hasSchoolOffers && widget.flow.schoolOffers.isNotEmpty) {
      final offer = widget.flow.schoolOffers.firstWhere(
        (item) => item.childId == widget.flow.primarySchoolOfferChildId,
        orElse: () => widget.flow.schoolOffers.first,
      );
      _firstNameController.text = offer.parentFirstName;
      _lastNameController.text = offer.parentLastName;
      _patronymicController.text = offer.parentPatronymic;
      if (offer.parentDateOfBirth.contains('-')) {
        final parts = offer.parentDateOfBirth.split('-');
        if (parts.length == 3) {
          _dateOfBirthController.text = '${parts[2]}.${parts[1]}.${parts[0]}';
        }
      }
    }
    _loadConfig();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _patronymicController.dispose();
    _networkNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordRepeatController.dispose();
    _dateOfBirthController.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    try {
      final locale = LocaleScope.of(context).localeCode;
      final config = await AuthScope.of(
        context,
      ).registerApi.fetchConfig(locale: locale);
      if (!mounted) {
        return;
      }
      setState(() {
        _config = config;
        _isLoadingConfig = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingConfig = false);
      }
    }
  }

  Map<String, String> _buildProfilePayload() {
    final payload = <String, String>{
      'firstName': _firstNameController.text.trim(),
      'password': _passwordController.text,
      'confirmPassword': _passwordRepeatController.text,
    };

    switch (widget.flow.accountType) {
      case RegisterAccountType.parent:
        payload['relationship'] = _selectedRelationship ?? 'mother';
        break;
      case RegisterAccountType.teacher:
        payload['lastName'] = _lastNameController.text.trim();
        payload['patronymic'] = _patronymicController.text.trim();
        final dateText = _dateOfBirthController.text.trim();
        payload['dateOfBirth'] =
            dateText.isEmpty ? '' : displayDateToIso(dateText) ?? '';
        if (_citySelection != null) {
          payload['placeMapboxId'] = _citySelection!.mapboxId;
          payload['city'] = _citySelection!.displayLabel;
        } else {
          payload['city'] = '';
        }
        break;
      case RegisterAccountType.networkOwner:
        payload['lastName'] = _lastNameController.text.trim();
        payload['patronymic'] = _patronymicController.text.trim();
        if (_citySelection != null) {
          payload['placeMapboxId'] = _citySelection!.mapboxId;
          payload['city'] = _citySelection!.displayLabel;
        } else {
          payload['city'] = '';
        }
        payload['networkDisplayName'] = _networkNameController.text.trim();
        if (widget.flow.channel == RegisterContactChannel.sms) {
          payload['email'] = _emailController.text.trim();
        }
        break;
    }

    return payload;
  }

  Future<void> _submit() async {
    final l10n = context.l10n;

    if (widget.flow.verificationToken.isEmpty) {
      setState(() => _error = l10n.verifyContactFirst);
      return;
    }

    if (_passwordController.text != _passwordRepeatController.text) {
      setState(() => _error = l10n.passwordsDoNotMatch);
      return;
    }

    if (!_termsAccepted || (_config?.termsVersionId.isEmpty ?? true)) {
      setState(() => _error = l10n.registrationTermsRequired);
      return;
    }

    if (widget.flow.accountType == RegisterAccountType.teacher &&
        _dateOfBirthController.text.trim().isNotEmpty) {
      final dateOfBirth = displayDateToIso(_dateOfBirthController.text.trim());
      if (dateOfBirth == null) {
        setState(() => _error = l10n.invalidDateOfBirth);
        return;
      }
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final locale = LocaleScope.of(context).localeCode;
      final auth = AuthScope.of(context);

      if (widget.flow.hasSchoolOffers) {
        if (!_authorityDeclared || !_consentAccepted) {
          setState(() {
            _error = l10n.parentConfirmFamilyChildrenConsentRequired;
            _isSubmitting = false;
          });
          return;
        }
        final primary = widget.flow.schoolOffers.firstWhere(
          (item) => item.childId == widget.flow.primarySchoolOfferChildId,
          orElse: () => widget.flow.schoolOffers.first,
        );
        final dob = displayDateToIso(_dateOfBirthController.text.trim());
        if (dob == null || _citySelection == null) {
          setState(() {
            _error = l10n.invalidDateOfBirth;
            _isSubmitting = false;
          });
          return;
        }
        final result = await auth.registerSchoolOffersApi.complete(
          payload: {
            'channel': widget.flow.channel == RegisterContactChannel.email ? 'email' : 'sms',
            'contact': widget.flow.contact,
            'verificationToken': widget.flow.verificationToken,
            'firstName': _firstNameController.text.trim(),
            'lastName': _lastNameController.text.trim(),
            'patronymic': _patronymicController.text.trim(),
            'dateOfBirth': dob,
            'password': _passwordController.text,
            'confirmPassword': _passwordRepeatController.text,
            'placeMapboxId': _citySelection!.mapboxId,
            'termsAccepted': _termsAccepted,
            'termsVersionId': _config!.termsVersionId,
            'idempotencyKey': _idempotencyKey,
            'childIds': widget.flow.selectedSchoolOfferChildIds,
            'primaryChildId': widget.flow.primarySchoolOfferChildId ?? primary.childId,
            'childFirstName': primary.childFirstName,
            'childLastName': primary.childLastName ?? '',
            'childPatronymic': primary.childPatronymic ?? '',
            'childDateOfBirth': primary.childDateOfBirth ?? '',
            'childGender': primary.childGender ?? 'male',
            'authorityBasis': 'parent',
            'authorityDeclared': true,
            'consentAccepted': true,
            'documentVersionId': _config!.childConsentVersionId,
            'childIdempotencyKey': _idempotencyKey,
          },
          locale: locale,
        );
        if (!mounted) {
          return;
        }
        final homePath = await auth.completeRegistration(result);
        if (!mounted) {
          return;
        }
        final pending = await auth.confirmFamilyChildrenApi.fetchPending(locale: locale);
        if (!mounted) {
          return;
        }
        if (pending != null) {
          context.go('/parent/family/confirm-children');
          return;
        }
        context.go(
          resolvePostAuthDestination(
            accountType: auth.user?.accountType,
            homePath: homePath,
            familySetupComplete: auth.familySetupComplete,
          ),
        );
        return;
      }

      final result = await auth.registerApi.register(
        flow: widget.flow,
        verificationToken: widget.flow.verificationToken,
        profile: _buildProfilePayload(),
        idempotencyKey: _idempotencyKey,
        termsVersionId: _config!.termsVersionId,
        locale: locale,
      );
      if (!mounted) {
        return;
      }
      final homePath = await auth.completeRegistration(result);
      if (!mounted) {
        return;
      }
      context.go(
        resolvePostAuthDestination(
          accountType: AuthScope.of(context).user?.accountType,
          homePath: homePath,
          familySetupComplete: AuthScope.of(context).familySetupComplete,
        ),
      );
    } on RegisterApiException catch (error) {
      setState(() => _error = error.message);
    } on RegisterSchoolOffersApiException catch (error) {
      setState(() => _error = error.message);
    } catch (_) {
      setState(() => _error = l10n.createAccountFailed);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AuthWebFlowShell(
      onBack: () => context.pop(),
      stepLabels: registerWizardStepLabels(context),
      currentStep: 3,
      stepTitle: registerProfileStepTitle(context, widget.flow.accountType),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_error != null) AuthErrorBanner(message: _error!),
          ..._buildFields(l10n),
          const SizedBox(height: 12),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _termsAccepted,
            onChanged: (value) =>
                setState(() => _termsAccepted = value ?? false),
            title: Text(_termsCheckboxText(l10n)),
            subtitle: Wrap(
              spacing: 12,
              children: [
                TextButton(
                  onPressed: _config?.termsPath.isNotEmpty == true
                      ? () => _openLegalPath(_config!.termsPath)
                      : null,
                  child: Text(l10n.registrationTermsLink),
                ),
                TextButton(
                  onPressed: _config?.privacyPath.isNotEmpty == true
                      ? () => _openLegalPath(_config!.privacyPath)
                      : null,
                  child: Text(l10n.registrationPrivacyLink),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          AuthPrimaryButton(
            label: l10n.createAccountButton,
            isLoading: _isSubmitting,
            useWebAuthStyle: true,
            onPressed: _isSubmitting || _isLoadingConfig ? null : _submit,
          ),
        ],
      ),
    );
  }

  Widget _cityField(AppLocalizations l10n) {
    final locale = LocaleScope.of(context).localeCode;
    return PlaceAutocompleteField(
      placesApi: AuthScope.of(context).placesApi,
      locale: locale,
      label: l10n.optionalCityLabel,
      optional: true,
      onChanged: (selection) => setState(() => _citySelection = selection),
    );
  }

  List<Widget> _buildFields(AppLocalizations l10n) {
    switch (widget.flow.accountType) {
      case RegisterAccountType.parent:
        if (widget.flow.hasSchoolOffers) {
          return [
            AuthInput(
              controller: _lastNameController,
              label: l10n.lastNameLabel,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            AuthInput(
              controller: _firstNameController,
              label: l10n.firstNameLabel,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            AuthInput(
              controller: _patronymicController,
              label: l10n.patronymicLabel,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            DateOfBirthTextField(
              controller: _dateOfBirthController,
              label: l10n.dateOfBirthLabel,
            ),
            const SizedBox(height: 12),
            _cityField(l10n),
            const SizedBox(height: 12),
            _passwordFields(l10n),
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
          ];
        }
        return [
          AuthInput(
            controller: _firstNameController,
            label: l10n.firstNameLabel,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          DropdownMenu<String>(
            initialSelection: _selectedRelationship,
            label: Text(l10n.registerParentRelationshipLabel),
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
          const SizedBox(height: 12),
          _passwordFields(l10n),
        ];
      case RegisterAccountType.teacher:
        return [
          AuthInput(
            controller: _lastNameController,
            label: l10n.lastNameLabel,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          AuthInput(
            controller: _firstNameController,
            label: l10n.firstNameLabel,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          AuthInput(
            controller: _patronymicController,
            label: l10n.optionalPatronymicLabel,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          DateOfBirthTextField(
            controller: _dateOfBirthController,
            label: l10n.optionalDateOfBirthLabel,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          _cityField(l10n),
          const SizedBox(height: 12),
          _passwordFields(l10n),
        ];
      case RegisterAccountType.networkOwner:
        return [
          AuthInput(
            controller: _networkNameController,
            label: l10n.networkNameLabel,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          AuthInput(
            controller: _firstNameController,
            label: l10n.firstNameLabel,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          AuthInput(
            controller: _lastNameController,
            label: l10n.lastNameLabel,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          AuthInput(
            controller: _patronymicController,
            label: l10n.optionalPatronymicLabel,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          _cityField(l10n),
          const SizedBox(height: 12),
          if (widget.flow.channel == RegisterContactChannel.email)
            AuthInput(
              controller: _emailController,
              label: l10n.emailLabel,
              readOnly: true,
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AuthInput(
                  controller: _emailController,
                  label: l10n.emailLabel,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.registrationOwnerEmailUnverifiedHint,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          const SizedBox(height: 12),
          _passwordFields(l10n),
        ];
    }
  }

  String _termsCheckboxText(AppLocalizations l10n) {
    switch (widget.flow.accountType) {
      case RegisterAccountType.parent:
        return l10n.registrationTermsParent;
      case RegisterAccountType.teacher:
        return l10n.registrationTermsTeacher;
      case RegisterAccountType.networkOwner:
        return l10n.registrationTermsNetworkOwner;
    }
  }

  Future<void> _openLegalPath(String path) async {
    final base = AppConfig.apiBaseUrl.replaceFirst(RegExp(r'/$'), '');
    await SharePlus.instance.share(ShareParams(text: '$base$path'));
  }

  Widget _passwordFields(AppLocalizations l10n) {
    return Column(
      children: [
        AuthInput(
          controller: _passwordController,
          label: l10n.passwordLabel,
          obscureText: true,
          enablePasswordToggle: true,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 12),
        AuthInput(
          controller: _passwordRepeatController,
          label: l10n.repeatPasswordLabel,
          obscureText: true,
          enablePasswordToggle: true,
          textInputAction: TextInputAction.done,
        ),
      ],
    );
  }
}
