import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:larnes_mobile/core/api/parent_api.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';
import 'package:larnes_mobile/features/parent/models/parent_child.dart';
import 'package:larnes_mobile/features/parent/utils/child_display.dart';
import 'package:larnes_mobile/features/parent/widgets/account/account_widgets.dart';
import 'package:larnes_mobile/features/parent/widgets/parent_scaffold.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

class AccountChildrenScreen extends StatefulWidget {
  const AccountChildrenScreen({super.key});

  @override
  State<AccountChildrenScreen> createState() => _AccountChildrenScreenState();
}

class _AccountChildrenScreenState extends State<AccountChildrenScreen> {
  bool _isLoading = true;
  String? _error;
  List<ParentChild> _children = const [];
  List<ParentChild> _archivedChildren = const [];
  String? _restoringChildId;
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
          _load(silent: _children.isNotEmpty);
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
      final api = AuthScope.of(context).parentApi;
      final children = await api.listChildren(locale: locale);
      final archivedChildren = await api.listArchivedChildren(locale: locale);
      if (!mounted) {
        return;
      }
      setState(() {
        _children = children;
        _archivedChildren = archivedChildren;
        _isLoading = false;
        _error = null;
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

  String _childTitle(ParentChild child) {
    final lines = childDisplayNameLines(child);
    return '${lines.lastName} ${lines.givenName}'.trim();
  }

  Future<void> _openAddChild() async {
    await context.push('/parent/children/new');
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

  Future<void> _restoreChild(String childId) async {
    setState(() {
      _restoringChildId = childId;
      _error = null;
    });
    try {
      final locale = LocaleScope.read(context).localeCode;
      await AuthScope.of(context).parentApi.restoreChild(childId, locale: locale);
      AuthScope.of(context).notifyParentDataChanged();
      await _load(silent: true);
    } on ParentApiException catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
      }
    } finally {
      if (mounted) {
        setState(() => _restoringChildId = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return ParentScaffold(
      title: l10n.parentAccountChildrenTitle,
      body: _buildBody(l10n),
    );
  }

  Widget _buildBody(dynamic l10n) {
    if (_isLoading && _children.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _children.isEmpty) {
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
            ],
          ),
        ),
      );
    }

    final localeCode = LocaleScope.of(context).localeCode;

    return AccountDeskShell(
      refreshIndicator: () => _load(silent: true),
      children: [
        AccountDeskCard(
          bandTitle: l10n.parentAccountChildrenProfiles,
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
            ],
          ),
        ),
        if (_archivedChildren.isNotEmpty)
          AccountDeskCard(
            bandTitle: l10n.parentAccountChildrenArchiveTitle,
            child: Column(
              children: [
                for (var i = 0; i < _archivedChildren.length; i++) ...[
                  if (i > 0) const AccountDivider(),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _childTitle(_archivedChildren[i]),
                          style: const TextStyle(
                            color: ParentColors.ink,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.parentAccountChildrenArchiveHint,
                          style: const TextStyle(color: ParentColors.inkMuted),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: _restoringChildId == null
                              ? () => _restoreChild(_archivedChildren[i].id)
                              : null,
                          child: _restoringChildId == _archivedChildren[i].id
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text(l10n.parentAccountChildrenRestore),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        AccountDeskCard(
          bandTitle: l10n.parentAccountChildrenActions,
          child: AccountLinkRow(
            label: l10n.parentAddChild,
            onTap: _openAddChild,
          ),
        ),
      ],
    );
  }
}
