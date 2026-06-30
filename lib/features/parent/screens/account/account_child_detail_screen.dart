import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:larnes_mobile/core/api/parent_api.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/parent/models/parent_child.dart';
import 'package:larnes_mobile/features/parent/utils/account_display.dart';
import 'package:larnes_mobile/features/parent/utils/child_display.dart';
import 'package:larnes_mobile/features/parent/widgets/account/account_widgets.dart';
import 'package:larnes_mobile/features/parent/widgets/parent_scaffold.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

class AccountChildDetailScreen extends StatefulWidget {
  const AccountChildDetailScreen({super.key, required this.childId});

  final String childId;

  @override
  State<AccountChildDetailScreen> createState() => _AccountChildDetailScreenState();
}

class _AccountChildDetailScreenState extends State<AccountChildDetailScreen> {
  bool _isLoading = true;
  String? _error;
  ParentChild? _child;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _load();
      }
    });
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final locale = LocaleScope.read(context).localeCode;
      final detail = await AuthScope.of(context).parentApi.fetchChild(widget.childId, locale: locale);
      if (!mounted) {
        return;
      }
      setState(() {
        _child = detail.child;
        _isLoading = false;
      });
    } on ParentApiException catch (error) {
      if (mounted) {
        setState(() {
          _error = error.message;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = context.l10n.parentLoadChildrenFailed;
          _isLoading = false;
        });
      }
    }
  }

  String _title(ParentChild child) {
    final lines = childDisplayNameLines(child);
    return '${lines.lastName} ${lines.givenName}'.trim();
  }

  String _genderLabel(String? gender, dynamic l10n) {
    if (gender == 'male') {
      return l10n.parentChildFormGenderMale;
    }
    if (gender == 'female') {
      return l10n.parentChildFormGenderFemale;
    }
    return l10n.parentAccountNotSet;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final child = _child;

    return ParentScaffold(
      title: child != null ? _title(child) : l10n.parentAccountChildrenTitle,
      backLabel: l10n.parentAccountChildrenBackToList,
      onBack: () => context.pop(),
      body: _buildBody(l10n),
    );
  }

  Widget _buildBody(dynamic l10n) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null || _child == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error ?? l10n.parentLoadChildrenFailed, textAlign: TextAlign.center),
        ),
      );
    }

    final child = _child!;
    final localeCode = LocaleScope.of(context).localeCode;
    final age = child.ageYears;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        AccountSection(
          title: l10n.parentAccountChildSummary,
          child: Column(
            children: [
              if (age != null)
                AccountFieldRow(
                  label: l10n.parentAccountChildAge,
                  value: formatChildAgeYears(age, localeCode),
                ),
              if (age != null) const AccountDivider(),
              AccountFieldRow(
                label: l10n.parentChildFormDateOfBirth,
                value: formatAccountDateOfBirth(child.dateOfBirth, localeCode),
              ),
              const AccountDivider(),
              AccountFieldRow(
                label: l10n.parentChildFormGender,
                value: _genderLabel(child.gender, l10n),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        AccountSection(
          title: l10n.parentAccountChildrenActions,
          child: AccountActionRow(
            label: l10n.parentAccountEditChild,
            onTap: () => context.push('/parent/account/children/${widget.childId}/edit'),
          ),
        ),
      ],
    );
  }
}
