import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:larnes_mobile/core/api/parent_api.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/parent/models/parent_child.dart';
import 'package:larnes_mobile/features/parent/widgets/add_child_card.dart';
import 'package:larnes_mobile/features/parent/widgets/child_profile_card.dart';
import 'package:larnes_mobile/features/parent/widgets/parent_scaffold.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

class ChildPickerScreen extends StatefulWidget {
  const ChildPickerScreen({super.key});

  @override
  State<ChildPickerScreen> createState() => _ChildPickerScreenState();
}

class _ChildPickerScreenState extends State<ChildPickerScreen> {
  bool _isLoading = true;
  bool _isRefreshing = false;
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
          _load(refreshing: _children.isNotEmpty);
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

  Future<void> _load({bool refreshing = false}) async {
    if (refreshing) {
      setState(() => _isRefreshing = true);
    } else if (_children.isEmpty) {
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
        _isRefreshing = false;
        _error = null;
      });
    } on ParentApiException catch (error) {
      if (mounted) {
        setState(() {
          _error = error.message;
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = context.l10n.parentLoadChildrenFailed;
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _openAddChild() async {
    final createdId = await context.push<String>('/parent/children/new');
    if (!mounted) {
      return;
    }

    await _load(refreshing: true);

    if (!mounted || createdId == null) {
      return;
    }

    await context.push('/parent/$createdId');
    if (mounted) {
      await _load(refreshing: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return ParentScaffold(
      title: l10n.parentChildPickerTitle,
      accountLabel: l10n.parentAccount,
      onAccount: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.parentAccountSoon)),
        );
      },
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final l10n = context.l10n;
    if (_isLoading && _children.isEmpty && _error == null) {
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
      onRefresh: () => _load(refreshing: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          if (_isRefreshing)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: LinearProgressIndicator(),
            ),
          for (final child in _children) ...[
            ChildProfileCard(
              child: child,
              onTap: () async {
                await context.push('/parent/${child.id}');
                if (mounted) {
                  await _load(refreshing: true);
                }
              },
            ),
            const SizedBox(height: 12),
          ],
          AddChildCard(
            label: l10n.parentAddChild,
            onTap: _openAddChild,
          ),
        ],
      ),
    );
  }
}
