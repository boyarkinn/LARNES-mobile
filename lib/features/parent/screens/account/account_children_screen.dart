import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:larnes_mobile/core/api/parent_api.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
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
      final children = await AuthScope.of(context).parentApi.listChildren(locale: locale);
      if (!mounted) {
        return;
      }
      setState(() {
        _children = children;
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return ParentScaffold(
      title: l10n.parentAccountChildrenTitle,
      backLabel: l10n.parentAccountBackToAccount,
      onBack: () => context.pop(),
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
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: _load, child: Text(l10n.continueButton)),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _load(silent: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          if (_children.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(l10n.parentAccountChildrenEmpty, style: const TextStyle(fontSize: 14)),
            ),
          if (_children.isNotEmpty)
            AccountSection(
              title: l10n.parentAccountChildrenProfiles,
              child: Column(
                children: [
                  for (var i = 0; i < _children.length; i++) ...[
                    if (i > 0) const AccountDivider(),
                    AccountActionRow(
                      label: _childTitle(_children[i]),
                      subtitle: _children[i].ageYears != null
                          ? formatChildAgeYears(_children[i].ageYears!, LocaleScope.of(context).localeCode)
                          : null,
                      onTap: () => context.push('/parent/account/children/${_children[i].id}'),
                    ),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 20),
          AccountSection(
            title: l10n.parentAccountChildrenActions,
            child: AccountActionRow(
              label: l10n.parentAddChild,
              onTap: () async {
                await context.push('/parent/children/new');
                if (mounted) {
                  await _load(silent: true);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
