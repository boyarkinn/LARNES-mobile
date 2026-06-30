import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:larnes_mobile/core/api/parent_account_api.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_text_field.dart';
import 'package:larnes_mobile/features/parent/widgets/parent_scaffold.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

class AccountCityScreen extends StatefulWidget {
  const AccountCityScreen({super.key});

  @override
  State<AccountCityScreen> createState() => _AccountCityScreenState();
}

class _AccountCityScreenState extends State<AccountCityScreen> {
  String? _selectedCity;
  List<String> _cities = const ['Москва'];
  bool _isLoadingConfig = true;
  bool _isSubmitting = false;
  String? _error;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _selectedCity = AuthScope.of(context).user?.city;
      _loadConfig();
    }
  }

  Future<void> _loadConfig() async {
    try {
      final config = await AuthScope.of(context).registerApi.fetchConfig();
      if (!mounted) {
        return;
      }
      setState(() {
        _cities = config.cities.isEmpty ? const ['Москва'] : config.cities;
        _selectedCity ??= _cities.first;
        if (_selectedCity != null && !_cities.contains(_selectedCity)) {
          _selectedCity = _cities.first;
        }
        _isLoadingConfig = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingConfig = false);
      }
    }
  }

  Future<void> _submit() async {
    final city = _selectedCity;
    if (city == null) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final locale = LocaleScope.of(context).localeCode;
      final user = await AuthScope.of(context).parentAccountApi.updateCity(
        city: city,
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
      title: l10n.parentAccountCityTitle,
      backLabel: l10n.parentAccountBackToAccount,
      onBack: () => context.pop(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null) AuthErrorBanner(message: _error!),
            DropdownMenu<String>(
              initialSelection: _selectedCity,
              label: Text(l10n.cityLabel),
              dropdownMenuEntries: _cities
                  .map((city) => DropdownMenuEntry(value: city, label: city))
                  .toList(),
              onSelected: (value) => setState(() => _selectedCity = value),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isSubmitting || _isLoadingConfig ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(l10n.parentAccountSaveCity),
            ),
          ],
        ),
      ),
    );
  }
}
