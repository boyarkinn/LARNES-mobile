import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';
import 'package:larnes_mobile/core/auth/auth_session.dart';
import 'package:larnes_mobile/features/parent/navigation/parent_child_routes.dart';
import 'package:larnes_mobile/core/api/parent_api.dart';
import 'package:larnes_mobile/core/api/parent_panel_error.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/parent/models/parent_child.dart';
import 'package:larnes_mobile/features/parent/widgets/add_child_card.dart';
import 'package:larnes_mobile/features/parent/widgets/child_profile_card.dart';
import 'package:larnes_mobile/features/parent/utils/family_setup_guard.dart';
import 'package:larnes_mobile/features/parent/widgets/parent_panel_error_panel.dart';
import 'package:larnes_mobile/features/parent/widgets/parent_scaffold.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

class ChildPickerScreen extends StatefulWidget {
  const ChildPickerScreen({super.key});

  @override
  State<ChildPickerScreen> createState() => _ChildPickerScreenState();
}

class _ChildPickerScreenState extends State<ChildPickerScreen> {
  AuthSession? _authSession;
  int _lastParentDataRevision = 0;
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _error;
  String? _errorCode;
  List<ParentChild> _children = const [];
  bool _wasInactive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _bindAuthSession();
      if (_redirectIfFamilySetupRequired()) {
        return;
      }
      _redirectIfConfirmChildrenRequired();
    });
  }

  bool _redirectIfFamilySetupRequired() {
    final auth = AuthScope.of(context);
    if (auth.familySetupComplete == true) {
      return false;
    }
    redirectToFamilySetupIfRequired(context, code: kFamilySetupRequiredCode);
    return true;
  }

  Future<void> _redirectIfConfirmChildrenRequired() async {
    try {
      final locale = LocaleScope.read(context).localeCode;
      final pending = await AuthScope.of(context).confirmFamilyChildrenApi.fetchPending(
            locale: locale,
          );
      if (!mounted) {
        return;
      }
      if (pending != null) {
        context.go('/parent/family/confirm-children');
        return;
      }
    } catch (_) {
      // ignore gate fetch errors — picker still loads
    }
    if (mounted) {
      _load();
    }
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
    if (_redirectIfFamilySetupRequired()) {
      return;
    }
    _load(refreshing: _children.isNotEmpty);
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

  @override
  void dispose() {
    _authSession?.removeListener(_handleAuthSessionChanged);
    super.dispose();
  }

  Future<void> _load({bool refreshing = false}) async {
    if (refreshing) {
      setState(() => _isRefreshing = true);
    } else if (_children.isEmpty) {
      setState(() {
        _isLoading = true;
        _error = null;
        _errorCode = null;
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
        _errorCode = null;
      });
    } on ParentApiException catch (error) {
      if (mounted && redirectToFamilySetupIfRequired(context, code: error.code)) {
        return;
      }
      if (mounted) {
        setState(() {
          _error = error.message;
          _errorCode = error.code;
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

    await ParentChildRoutes.openChild(context, createdId);
    if (mounted) {
      await _load(refreshing: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return ParentScaffold(
      title: l10n.parentChildPickerTitle,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final l10n = context.l10n;
    if (_isLoading && _children.isEmpty && _error == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _children.isEmpty) {
      return ParentPanelErrorPanel(
        message: _error!,
        showFamilySetupAction: isFamilySetupRequiredCode(_errorCode),
        onFamilySetup: () => redirectToFamilySetupIfRequired(
          context,
          code: _errorCode,
        ),
        onRetry: _load,
      );
    }

    return RefreshIndicator(
      onRefresh: () => _load(refreshing: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 22, 16, 36),
        children: [
          if (_isRefreshing)
            const Padding(
              padding: EdgeInsets.only(bottom: ParentChildCardMetrics.pickerListGap),
              child: LinearProgressIndicator(),
            ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: ParentChildCardMetrics.pickerMaxWidth),
              child: Column(
                children: [
                  for (final child in _children) ...[
                    ChildProfileCard(
                      child: child,
                      onTap: () async {
                        await ParentChildRoutes.openChild(context, child.id);
                        if (mounted) {
                          await _load(refreshing: true);
                        }
                      },
                    ),
                    const SizedBox(height: ParentChildCardMetrics.pickerListGap),
                  ],
                  AddChildCard(
                    label: l10n.parentAddChild,
                    onTap: _openAddChild,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
