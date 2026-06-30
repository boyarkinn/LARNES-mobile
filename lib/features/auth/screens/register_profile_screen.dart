import 'package:flutter/material.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/api/register_api.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/auth/models/register_flow.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_scaffold.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_text_field.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

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

  String? _selectedCity;
  List<String> _cities = const ['Москва'];
  bool _isLoadingConfig = true;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.flow.accountType == RegisterAccountType.networkOwner &&
        widget.flow.channel == RegisterContactChannel.email) {
      _emailController.text = widget.flow.contact;
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
      final config = await AuthScope.of(context).registerApi.fetchConfig();
      if (!mounted) {
        return;
      }
      setState(() {
        _cities = config.cities.isEmpty ? const ['Москва'] : config.cities;
        _selectedCity = _cities.first;
        _isLoadingConfig = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingConfig = false);
      }
    }
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 25),
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

  Map<String, String> _buildProfilePayload() {
    final payload = <String, String>{
      'firstName': _firstNameController.text.trim(),
      'password': _passwordController.text,
      'confirmPassword': _passwordRepeatController.text,
    };

    switch (widget.flow.accountType) {
      case RegisterAccountType.parent:
        break;
      case RegisterAccountType.teacher:
        payload['lastName'] = _lastNameController.text.trim();
        payload['patronymic'] = _patronymicController.text.trim();
        payload['dateOfBirth'] = _dateOfBirthController.text.trim();
        payload['city'] = _selectedCity ?? _cities.first;
        break;
      case RegisterAccountType.networkOwner:
        payload['lastName'] = _lastNameController.text.trim();
        payload['patronymic'] = _patronymicController.text.trim();
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

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final locale = LocaleScope.of(context).localeCode;
      final result = await AuthScope.of(context).registerApi.register(
        flow: widget.flow,
        verificationToken: widget.flow.verificationToken,
        profile: _buildProfilePayload(),
        locale: locale,
      );
      if (!mounted) {
        return;
      }
      await AuthScope.of(context).completeRegistration(result);
      if (!mounted) {
        return;
      }
      context.go('/home');
    } on RegisterApiException catch (error) {
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

    return AuthScaffold(
      showBackButton: true,
      onBack: () => context.pop(),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthHeader(
              title: l10n.profileTitle,
              subtitle: l10n.registerStep3Subtitle(
                widget.flow.accountType.label(context),
              ),
            ),
            if (_error != null) AuthErrorBanner(message: _error!),
            ..._buildFields(l10n),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _isSubmitting || _isLoadingConfig ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.createAccountButton),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFields(AppLocalizations l10n) {
    switch (widget.flow.accountType) {
      case RegisterAccountType.parent:
        return [
          AuthTextField(
            controller: _firstNameController,
            label: l10n.firstNameLabel,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          _passwordFields(l10n),
        ];
      case RegisterAccountType.teacher:
        return [
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
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          AuthTextField(
            controller: _dateOfBirthController,
            label: l10n.dateOfBirthLabel,
            readOnly: true,
            onTap: _pickDateOfBirth,
          ),
          const SizedBox(height: 12),
          DropdownMenu<String>(
            initialSelection: _selectedCity,
            label: Text(l10n.cityLabel),
            dropdownMenuEntries: _cities
                .map((city) => DropdownMenuEntry(value: city, label: city))
                .toList(),
            onSelected: (value) => setState(() => _selectedCity = value),
          ),
          const SizedBox(height: 12),
          _passwordFields(l10n),
        ];
      case RegisterAccountType.networkOwner:
        return [
          AuthTextField(
            controller: _networkNameController,
            label: l10n.networkNameLabel,
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
            controller: _lastNameController,
            label: l10n.lastNameLabel,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          AuthTextField(
            controller: _patronymicController,
            label: l10n.patronymicLabel,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          if (widget.flow.channel == RegisterContactChannel.email)
            AuthTextField(
              controller: _emailController,
              label: l10n.emailLabel,
              readOnly: true,
            )
          else
            AuthTextField(
              controller: _emailController,
              label: l10n.emailLabel,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
            ),
          const SizedBox(height: 12),
          _passwordFields(l10n),
        ];
    }
  }

  Widget _passwordFields(AppLocalizations l10n) {
    return Column(
      children: [
        AuthTextField(
          controller: _passwordController,
          label: l10n.passwordLabel,
          obscureText: true,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 12),
        AuthTextField(
          controller: _passwordRepeatController,
          label: l10n.repeatPasswordLabel,
          obscureText: true,
          textInputAction: TextInputAction.done,
        ),
      ],
    );
  }
}
