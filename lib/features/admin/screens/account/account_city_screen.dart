import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:larnes_mobile/core/api/admin_account_api.dart';
import 'package:larnes_mobile/core/api/places_api.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/core/widgets/place_autocomplete_field.dart';
import 'package:larnes_mobile/features/admin/widgets/admin_account_scaffold.dart';
import 'package:larnes_mobile/features/admin/widgets/admin_account_widgets.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_text_field.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

class AdminAccountCityScreen extends StatefulWidget {
  const AdminAccountCityScreen({super.key});
  @override
  State<AdminAccountCityScreen> createState() => _AdminAccountCityScreenState();
}

class _AdminAccountCityScreenState extends State<AdminAccountCityScreen> {
  PlaceCitySelection? _selection;
  bool _dirty = false;
  bool _pending = false;
  String? _error;
  Future<void> _save() async {
    if (!_dirty) {
      context.pop();
      return;
    }
    final selection = _selection;
    if (selection == null ||
        (selection.mapboxId.isEmpty && selection.displayLabel.isNotEmpty)) {
      setState(() => _error = context.l10n.placesAutocompleteInvalidSelection);
      return;
    }
    setState(() {
      _pending = true;
      _error = null;
    });
    try {
      final session = AuthScope.of(context);
      final user = await session.adminAccountApi.updateCity(
        placeMapboxId: selection.mapboxId,
        locale: LocaleScope.of(context).localeCode,
      );
      if (!mounted) return;
      session.applyUser(user);
      context.pop();
    } on AdminAccountApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = context.l10n.adminAccountSaveFailed);
    } finally {
      if (mounted) setState(() => _pending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AdminAccountScaffold(
      title: l10n.parentAccountCityTitle,
      body: AdminAccountFormShell(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null) AuthErrorBanner(message: _error!),
            PlaceAutocompleteField(
              placesApi: AuthScope.of(context).placesApi,
              locale: LocaleScope.of(context).localeCode,
              label: l10n.cityLabel,
              initialDisplayLabel: AuthScope.of(context).user?.city ?? '',
              optional: true,
              onChanged: (selection) => setState(() {
                _selection = selection;
                _dirty = true;
              }),
            ),
            const SizedBox(height: 24),
            AdminAccountPrimaryButton(
              label: l10n.parentAccountSaveCity,
              isLoading: _pending,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
