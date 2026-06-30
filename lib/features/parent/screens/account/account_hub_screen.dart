import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:larnes_mobile/core/api/parent_account_api.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/auth/widgets/language_switcher.dart';
import 'package:larnes_mobile/features/parent/utils/account_display.dart';
import 'package:larnes_mobile/features/parent/widgets/account/account_widgets.dart';
import 'package:larnes_mobile/features/parent/widgets/parent_scaffold.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

class AccountHubScreen extends StatefulWidget {
  const AccountHubScreen({super.key});

  @override
  State<AccountHubScreen> createState() => _AccountHubScreenState();
}

class _AccountHubScreenState extends State<AccountHubScreen> {
  bool _isLoading = true;
  String? _error;
  ParentAccountSnapshot? _snapshot;
  bool _wasInactive = false;

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
  void activate() {
    super.activate();
    if (_wasInactive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _load(silent: _snapshot != null);
        }
      });
    }
    _wasInactive = false;
  }

  @override
  void deactivate() {
    _wasInactive = true;
    super.deactivate();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final locale = LocaleScope.read(context).localeCode;
      final snapshot = await AuthScope.of(context).parentAccountApi.fetchAccount(locale: locale);
      if (!mounted) {
        return;
      }
      AuthScope.of(context).applyUser(snapshot.user);
      setState(() {
        _snapshot = snapshot;
        _isLoading = false;
        _error = null;
      });
    } on ParentAccountApiException catch (error) {
      if (mounted) {
        setState(() {
          _error = error.message;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = context.l10n.parentAccountLoadFailed;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    await AuthScope.of(context).logout();
    if (mounted) {
      context.go('/login');
    }
  }

  Future<void> _logoutAll() async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.parentAccountLogoutAllTitle),
        content: Text(l10n.parentAccountLogoutAllMessage),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.parentAccountCancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.parentAccountLogoutAllConfirm)),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }

    try {
      final locale = LocaleScope.of(context).localeCode;
      await AuthScope.of(context).parentAccountApi.logoutAllDevices(locale: locale);
      await AuthScope.of(context).logout();
      if (mounted) {
        context.go('/login');
      }
    } on ParentAccountApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  void _showSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.parentAccountContactChangeSoon)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return ParentScaffold(
      title: l10n.parentAccountTitle,
      backLabel: l10n.parentAccountBackToPicker,
      onBack: () => context.pop(),
      body: _buildBody(l10n),
    );
  }

  Widget _buildBody(dynamic l10n) {
    if (_isLoading && _snapshot == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _snapshot == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: _load, child: Text(l10n.continueButton)),
            ],
          ),
        ),
      );
    }

    final user = _snapshot!.user;
    final localeCode = LocaleScope.of(context).localeCode;
    final formattedDob = formatAccountDateOfBirth(user.dateOfBirth, localeCode);
    const passwordMask = '••••••••';

    return RefreshIndicator(
      onRefresh: () => _load(silent: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          AccountSection(
            title: l10n.parentAccountSectionProfile,
            child: Column(
              children: [
                AccountFieldRow(
                  label: l10n.parentAccountFieldFullName,
                  value: user.fullName.isNotEmpty ? user.fullName : l10n.parentAccountNotSet,
                  muted: user.fullName.isEmpty,
                ),
                const AccountDivider(),
                AccountActionRow(
                  label: l10n.parentAccountActionChangeProfile,
                  onTap: () => context.push('/parent/account/profile'),
                ),
                const AccountDivider(),
                AccountFieldRow(
                  label: l10n.parentAccountFieldDateOfBirth,
                  value: formattedDob.isNotEmpty ? formattedDob : l10n.parentAccountDateOfBirthNotSet,
                  muted: formattedDob.isEmpty,
                ),
                const AccountDivider(),
                AccountActionRow(
                  label: l10n.parentAccountActionChangeDateOfBirth,
                  onTap: () => context.push('/parent/account/date-of-birth'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          AccountSection(
            title: l10n.parentAccountSectionChildren,
            child: Column(
              children: [
                AccountFieldRow(
                  label: l10n.parentAccountFieldChildren,
                  value: formatChildrenCount(l10n, _snapshot!.childrenCount),
                ),
                const AccountDivider(),
                AccountActionRow(
                  label: l10n.parentAccountActionManageChildren,
                  onTap: () => context.push('/parent/account/children'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          AccountSection(
            title: l10n.parentAccountSectionCity,
            child: Column(
              children: [
                AccountFieldRow(
                  label: l10n.parentAccountFieldCity,
                  value: user.city ?? l10n.parentAccountCityNotSet,
                  muted: user.city == null || user.city!.isEmpty,
                ),
                const AccountDivider(),
                AccountActionRow(
                  label: l10n.parentAccountActionChangeCity,
                  onTap: () => context.push('/parent/account/city'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          AccountSection(
            title: l10n.parentAccountSectionContacts,
            child: Column(
              children: [
                AccountFieldRow(
                  label: l10n.phoneLabel,
                  value: user.phone ?? l10n.parentAccountNotSet,
                  muted: user.phone == null,
                  badgeLabel: user.phone != null
                      ? (user.phoneVerified
                          ? l10n.parentAccountContactVerified
                          : l10n.parentAccountContactNotVerified)
                      : null,
                  badgeVerified: user.phoneVerified,
                ),
                const AccountDivider(),
                AccountActionRow(
                  label: l10n.parentAccountActionChangePhone,
                  onTap: _showSoon,
                ),
                const AccountDivider(),
                AccountFieldRow(
                  label: l10n.emailLabel,
                  value: user.email ?? l10n.parentAccountNotSet,
                  muted: user.email == null,
                  badgeLabel: user.email != null
                      ? (user.emailVerified
                          ? l10n.parentAccountContactVerified
                          : l10n.parentAccountContactNotVerified)
                      : null,
                  badgeVerified: user.emailVerified,
                ),
                const AccountDivider(),
                AccountActionRow(
                  label: l10n.parentAccountActionChangeEmail,
                  onTap: _showSoon,
                ),
                const AccountDivider(),
                AccountFieldRow(
                  label: l10n.parentAccountFieldLogin,
                  value: user.login ?? l10n.parentAccountNotSet,
                  muted: user.login == null,
                ),
                const AccountDivider(),
                AccountActionRow(
                  label: l10n.parentAccountActionChangeLogin,
                  onTap: () => context.push('/parent/account/login'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          AccountSection(
            title: l10n.parentAccountSectionSecurity,
            child: Column(
              children: [
                AccountFieldRow(
                  label: l10n.passwordLabel,
                  value: passwordMask,
                ),
                const AccountDivider(),
                AccountActionRow(
                  label: l10n.parentAccountActionChangePassword,
                  onTap: () => context.push('/parent/account/password'),
                ),
                const AccountDivider(),
                AccountActionRow(
                  label: l10n.parentAccountActionLogoutAll,
                  destructive: true,
                  onTap: _logoutAll,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          AccountSection(
            title: l10n.parentAccountSectionLanguage,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Align(
                alignment: Alignment.centerRight,
                child: LanguageSwitcher(),
              ),
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: _logout,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red.shade700,
              side: BorderSide(color: Colors.red.shade300),
              minimumSize: const Size.fromHeight(48),
            ),
            child: Text(l10n.logoutButton),
          ),
        ],
      ),
    );
  }
}
