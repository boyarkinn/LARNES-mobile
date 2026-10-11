import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:larnes_mobile/core/api/parent_account_api.dart';
import 'package:larnes_mobile/core/api/places_api.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/core/widgets/place_autocomplete_field.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_text_field.dart';
import 'package:larnes_mobile/features/parent/widgets/account/account_widgets.dart';
import 'package:larnes_mobile/features/parent/widgets/parent_scaffold.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

class AccountCityScreen extends StatefulWidget {
  const AccountCityScreen({super.key});

  @override
  State<AccountCityScreen> createState() => _AccountCityScreenState();
}

class _AccountCityScreenState extends State<AccountCityScreen> {
  PlaceCitySelection? _citySelection;
  bool _isSubmitting = false;
  String? _error;
  bool _initialized = false;
  String _originalCity = '';
  bool _selectionDirty = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _originalCity = AuthScope.of(context).user?.city?.trim() ?? '';
    }
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    if (!_selectionDirty) {
      context.pop();
      return;
    }

    final selection = _citySelection;
    if (selection == null ||
        (selection.mapboxId.isEmpty && selection.displayLabel.isNotEmpty)) {
      setState(() => _error = l10n.placesAutocompleteInvalidSelection);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final locale = LocaleScope.of(context).localeCode;
      final user = await AuthScope.of(context).parentAccountApi.updateCity(
        placeMapboxId: selection.mapboxId,
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
    final locale = LocaleScope.of(context).localeCode;

    return ParentScaffold(
      title: l10n.parentAccountCityTitle,
      body: AccountDeskFormShell(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null) AuthErrorBanner(message: _error!),
            PlaceAutocompleteField(
              placesApi: AuthScope.of(context).placesApi,
              locale: locale,
              label: l10n.cityLabel,
              initialDisplayLabel: _originalCity,
              optional: true,
              onChanged: (selection) => setState(() {
                _citySelection = selection;
                _selectionDirty = true;
              }),
            ),
            const SizedBox(height: 24),
            AccountPrimaryButton(
              label: l10n.parentAccountSaveCity,
              isLoading: _isSubmitting,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
