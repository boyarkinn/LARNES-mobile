import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';
import 'package:larnes_mobile/core/api/guardians_api.dart';
import 'package:larnes_mobile/core/api/parent_account_api.dart';
import 'package:larnes_mobile/core/api/parent_api.dart';
import 'package:larnes_mobile/core/api/parent_panel_error.dart';
import 'package:larnes_mobile/core/auth/auth_session.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/parent/models/parent_child.dart';
import 'package:larnes_mobile/features/parent/utils/account_display.dart';
import 'package:larnes_mobile/features/parent/utils/child_display.dart';
import 'package:larnes_mobile/features/parent/utils/guardian_relationship_display.dart';
import 'package:larnes_mobile/features/parent/widgets/account/account_family_section.dart';
import 'package:larnes_mobile/features/parent/widgets/account/account_language_picker.dart';
import 'package:larnes_mobile/features/parent/widgets/account/account_widgets.dart';
import 'package:larnes_mobile/features/parent/widgets/account/account_widgets.dart';
import 'package:larnes_mobile/features/parent/widgets/parent_scaffold.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

class AccountHubScreen extends StatefulWidget {
  const AccountHubScreen({super.key});

  @override
  State<AccountHubScreen> createState() => _AccountHubScreenState();
}

class _AccountHubScreenState extends State<AccountHubScreen> {
  AuthSession? _authSession;
  int _lastParentDataRevision = 0;
  bool _isLoading = true;
  String? _error;
  String? _errorCode;
  ParentAccountSnapshot? _snapshot;
  List<ParentChild> _children = const [];
  GuardiansSnapshot? _guardians;
  bool _wasInactive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _bindAuthSession();
        _load();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bindAuthSession();
  }

  void _bindAuthSession() {
    final auth = AuthScope.of(context);
    if (identical(_authSession, auth)) {
      return;
    }

    _authSession?.removeListener(_handleAuthSessionChanged);
    _authSession = auth;
    _lastParentDataRevision = auth.parentDataRevision;
    auth.addListener(_handleAuthSessionChanged);
  }

  void _handleAuthSessionChanged() {
    final auth = _authSession;
    if (auth == null || !mounted) {
      return;
    }

    if (auth.parentDataRevision == _lastParentDataRevision) {
      return;
    }

    _lastParentDataRevision = auth.parentDataRevision;
    _load(silent: _snapshot != null);
  }

  @override
  void dispose() {
    _authSession?.removeListener(_handleAuthSessionChanged);
    super.dispose();
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
        _errorCode = null;
      });
    }

    try {
      final locale = LocaleScope.read(context).localeCode;
      final auth = AuthScope.of(context);
      final account = await auth.parentAccountApi.fetchAccount(locale: locale);
      List<ParentChild> children = const [];
      try {
        children = await auth.parentApi.listChildren(locale: locale);
      } on ParentApiException {
        children = const [];
      }
      GuardiansSnapshot? guardians;
      try {
        guardians = await auth.guardiansApi.fetchGuardians(locale: locale);
      } catch (_) {
        guardians = null;
      }
      if (!mounted) {
        return;
      }
      auth.applyUser(account.user);
      setState(() {
        _snapshot = account;
        _children = children;
        _guardians = guardians;
        _isLoading = false;
        _error = null;
        _errorCode = null;
      });
    } on ParentAccountApiException catch (error) {
      if (mounted) {
        setState(() {
          _error = error.message;
          _errorCode = error.code;
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

  Future<void> _openAddChild() async {
    await context.push('/parent/children/new');
    if (mounted) {
      await _load(silent: true);
    }
  }

  /// После редактирования sub-page: go_router не всегда вызывает activate на hub.
  Future<void> _openAccountRoute(String path) async {
    await context.push(path);
    if (mounted) {
      await _load(silent: true);
    }
  }

  Future<void> _openChildProfile(String childId) async {
    await context.push('/parent/$childId/profile?from=account');
    if (mounted) {
      await _load(silent: true);
    }
  }

  String _childTitle(ParentChild child) {
    final lines = childDisplayNameLines(child);
    return '${lines.lastName} ${lines.givenName}'.trim();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return ParentScaffold(
      title: l10n.parentAccountTitle,
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
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: ParentColors.inkMuted)),
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: ParentColors.shell),
                onPressed: _load,
                child: Text(l10n.continueButton),
              ),
              const SizedBox(height: 12),
              TextButton(onPressed: _logout, child: Text(l10n.logoutButton)),
            ],
          ),
        ),
      );
    }

    final user = _snapshot!.user;
    final localeCode = LocaleScope.of(context).localeCode;
    final formattedDob = formatAccountDateOfBirth(user.dateOfBirth, localeCode);
    final selfRelationship = selfGuardianRelationship(_guardians);
    const passwordMask = '••••••••';

    return AccountDeskShell(
      refreshIndicator: () => _load(silent: true),
      children: [
        AccountDeskCard(
          bandTitle: l10n.parentAccountSectionProfile,
          child: Column(
            children: [
              AccountFieldGroup(
                label: l10n.parentAccountFieldFullName,
                value: user.fullName.isNotEmpty ? user.fullName : l10n.parentAccountNotSet,
                valueMuted: user.fullName.isEmpty,
                onTap: () => _openAccountRoute('/parent/account/profile'),
              ),
              const AccountDivider(),
              AccountFieldGroup(
                label: l10n.parentAccountFieldDateOfBirth,
                value: formattedDob.isNotEmpty ? formattedDob : l10n.parentAccountDateOfBirthNotSet,
                valueMuted: formattedDob.isEmpty,
                onTap: () => _openAccountRoute('/parent/account/date-of-birth'),
              ),
              if (selfRelationship != null) ...[
                const AccountDivider(),
                AccountFieldGroup(
                  label: l10n.parentAccountFieldRelationship,
                  value: guardianRelationshipLabel(l10n, selfRelationship),
                  onTap: () => _openAccountRoute(
                    '/parent/account/relationship?relationship=${Uri.encodeComponent(selfRelationship)}',
                  ),
                ),
              ],
              const AccountDivider(),
              AccountFieldGroup(
                label: l10n.parentAccountFieldCity,
                value: user.city ?? l10n.parentAccountCityNotSet,
                valueMuted: user.city == null || user.city!.isEmpty,
                onTap: () => _openAccountRoute('/parent/account/city'),
              ),
            ],
          ),
        ),
        AccountDeskCard(
          bandTitle: l10n.parentAccountSectionContacts,
          child: Column(
            children: [
              AccountFieldGroup(
                label: l10n.phoneLabel,
                value: user.phone ?? l10n.parentAccountNotSet,
                valueMuted: user.phone == null,
                badgeLabel: user.phone != null
                    ? (user.phoneVerified
                        ? l10n.parentAccountContactVerified
                        : l10n.parentAccountContactNotVerified)
                    : null,
                badgeVerified: user.phoneVerified,
                onTap: () => _openAccountRoute('/parent/account/phone'),
              ),
              const AccountDivider(),
              AccountFieldGroup(
                label: l10n.emailLabel,
                value: user.email ?? l10n.parentAccountNotSet,
                valueMuted: user.email == null,
                badgeLabel: user.email != null
                    ? (user.emailVerified
                        ? l10n.parentAccountContactVerified
                        : l10n.parentAccountContactNotVerified)
                    : null,
                badgeVerified: user.emailVerified,
                onTap: () => _openAccountRoute('/parent/account/email'),
              ),
              const AccountDivider(),
              AccountFieldGroup(
                label: l10n.parentAccountFieldLogin,
                value: user.login ?? l10n.parentAccountNotSet,
                valueMuted: user.login == null,
                onTap: () => _openAccountRoute('/parent/account/login'),
              ),
            ],
          ),
        ),
        AccountDeskCard(
          bandTitle: l10n.parentAccountSectionChildren,
          child: Column(
            children: [
              if (_children.isEmpty)
                AccountEmptyText(text: l10n.parentAccountChildrenEmpty)
              else
                for (var i = 0; i < _children.length; i++) ...[
                  if (i > 0) const AccountDivider(),
                  AccountChildRow(
                    name: _childTitle(_children[i]),
                    meta: _children[i].ageYears != null
                        ? formatChildAgeYears(_children[i].ageYears!, localeCode)
                        : null,
                    onTap: () => _openChildProfile(_children[i].id),
                  ),
                ],
              if (_children.isNotEmpty) const AccountDivider(),
              AccountLinkRow(
                label: l10n.parentAddChild,
                onTap: _openAddChild,
              ),
            ],
          ),
        ),
        AccountDeskCard(
          bandTitle: l10n.parentAccountSectionFamily,
          child: AccountFamilySection(
            snapshot: _guardians,
            onChanged: () => _load(silent: true),
          ),
        ),
        AccountDeskCard(
          bandTitle: l10n.parentAccountSectionLanguage,
          child: const AccountLanguagePicker(),
        ),
        AccountDeskCard(
          bandTitle: l10n.parentAccountSectionSecurity,
          child: Column(
            children: [
              AccountFieldGroup(
                label: l10n.passwordLabel,
                value: passwordMask,
                onTap: () => _openAccountRoute('/parent/account/password'),
              ),
              const AccountDivider(),
              AccountDestructiveButton(
                label: l10n.parentAccountActionLogoutAll,
                onTap: _logoutAll,
              ),
              const AccountDivider(),
              AccountDestructiveButton(
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
