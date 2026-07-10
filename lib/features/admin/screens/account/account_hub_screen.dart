import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:larnes_mobile/app/theme/admin_theme.dart';
import 'package:larnes_mobile/core/api/admin_account_api.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/admin/widgets/admin_account_language_picker.dart';
import 'package:larnes_mobile/features/admin/widgets/admin_account_widgets.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

class AdminAccountHubScreen extends StatefulWidget {
  const AdminAccountHubScreen({super.key});

  @override
  State<AdminAccountHubScreen> createState() => _AdminAccountHubScreenState();
}

class _AdminAccountHubScreenState extends State<AdminAccountHubScreen> {
  bool _isLoading = true;
  String? _error;
  AdminAccountSnapshot? _snapshot;
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
      final snapshot = await AuthScope.of(context).adminAccountApi.fetchAccount(locale: locale);
      if (!mounted) {
        return;
      }
      AuthScope.of(context).applyUser(snapshot.user);
      setState(() {
        _snapshot = snapshot;
        _isLoading = false;
        _error = null;
      });
    } on AdminAccountApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = context.l10n.adminAccountLoadFailed;
        _isLoading = false;
      });
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
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.parentAccountCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.parentAccountLogoutAllConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }

    try {
      final locale = LocaleScope.of(context).localeCode;
      await AuthScope.of(context).adminAccountApi.logoutAllDevices(locale: locale);
      await AuthScope.of(context).logout();
      if (mounted) {
        context.go('/login');
      }
    } on AdminAccountApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  Future<void> _openAccountRoute(String path) async {
    await context.push(path);
    if (mounted) {
      await _load(silent: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: AdminColors.background,
      appBar: AppBar(
        backgroundColor: AdminColors.surface,
        foregroundColor: AdminColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(l10n.adminAccountTitle),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AdminColors.line),
        ),
      ),
      body: _buildBody(l10n),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_isLoading && _snapshot == null) {
      return const Center(child: CircularProgressIndicator(color: AdminColors.accent));
    }

    if (_error != null && _snapshot == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AdminColors.inkMuted),
              ),
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AdminColors.accent),
                onPressed: _load,
                child: Text(l10n.continueButton),
              ),
            ],
          ),
        ),
      );
    }

    final user = _snapshot!.user;
    const passwordMask = '••••••••';

    return AdminAccountShell(
      refreshIndicator: () => _load(silent: true),
      children: [
        AdminAccountCard(
          title: l10n.adminAccountSectionProfile,
          child: AdminAccountFieldGroup(
            label: l10n.parentAccountFieldFullName,
            value: user.fullName.isNotEmpty ? user.fullName : l10n.adminAccountNotSet,
            valueMuted: user.fullName.isEmpty,
            onTap: () => _openAccountRoute('/admin/account/profile'),
          ),
        ),
        AdminAccountCard(
          title: l10n.adminAccountSectionContacts,
          child: Column(
            children: [
              AdminAccountFieldGroup(
                label: l10n.phoneLabel,
                value: user.phone ?? l10n.adminAccountNotSet,
                valueMuted: user.phone == null,
                badgeLabel: user.phone != null
                    ? (user.phoneVerified
                        ? l10n.parentAccountContactVerified
                        : l10n.parentAccountContactNotVerified)
                    : null,
                badgeVerified: user.phoneVerified,
                onTap: () => _openAccountRoute('/admin/account/phone'),
              ),
              const AdminAccountDivider(),
              AdminAccountFieldGroup(
                label: l10n.emailLabel,
                value: user.email ?? l10n.adminAccountNotSet,
                valueMuted: user.email == null,
                badgeLabel: user.email != null
                    ? (user.emailVerified
                        ? l10n.parentAccountContactVerified
                        : l10n.parentAccountContactNotVerified)
                    : null,
                badgeVerified: user.emailVerified,
                onTap: () => _openAccountRoute('/admin/account/email'),
              ),
              const AdminAccountDivider(),
              AdminAccountFieldGroup(
                label: l10n.parentAccountFieldLogin,
                value: user.login ?? l10n.adminAccountNotSet,
                valueMuted: user.login == null,
                onTap: () => _openAccountRoute('/admin/account/login'),
              ),
            ],
          ),
        ),
        AdminAccountCard(
          title: l10n.adminAccountSectionLanguage,
          child: const AdminAccountLanguagePicker(),
        ),
        AdminAccountCard(
          title: l10n.adminAccountSectionSecurity,
          child: Column(
            children: [
              AdminAccountFieldGroup(
                label: l10n.passwordLabel,
                value: passwordMask,
                onTap: () => _openAccountRoute('/admin/account/password'),
              ),
              const AdminAccountDivider(),
              AdminAccountDestructiveButton(
                label: l10n.adminAccountActionLogoutAll,
                onTap: _logoutAll,
              ),
              const AdminAccountDivider(),
              AdminAccountDestructiveButton(
                label: l10n.logoutButton,
                onTap: _logout,
                filled: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
