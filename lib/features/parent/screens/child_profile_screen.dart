import 'package:flutter/material.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';
import 'package:larnes_mobile/core/api/parent_api.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/parent/models/parent_child.dart';
import 'package:larnes_mobile/features/parent/theme/child_card_colors.dart';
import 'package:larnes_mobile/features/parent/utils/child_display.dart';
import 'package:larnes_mobile/features/parent/widgets/account/account_widgets.dart';
import 'package:larnes_mobile/features/parent/widgets/account/child_classroom_qr_card.dart';
import 'package:larnes_mobile/features/parent/widgets/account/child_education_profile.dart';
import 'package:larnes_mobile/features/parent/widgets/account/delete_child_panel.dart';
import 'package:larnes_mobile/features/parent/widgets/account/edit_child_form_panel.dart';
import 'package:larnes_mobile/features/parent/widgets/parent_scaffold.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

/// Откуда открыли профиль ребёнка (web `?from=account`).
enum ChildProfileOrigin {
  hub,
  account,
}

ChildProfileOrigin childProfileOriginFromQuery(String? from) {
  return from == 'account' ? ChildProfileOrigin.account : ChildProfileOrigin.hub;
}

/// Профиль ребёнка — canonical `/parent/:childId/profile`.
/// Эталон: platform `/parent/:childId/profile/page.tsx`
class ChildProfileScreen extends StatefulWidget {
  const ChildProfileScreen({
    super.key,
    required this.childId,
    this.origin = ChildProfileOrigin.hub,
  });

  final String childId;
  final ChildProfileOrigin origin;

  @override
  State<ChildProfileScreen> createState() => _ChildProfileScreenState();
}

class _ChildProfileScreenState extends State<ChildProfileScreen> {
  final _qrCardKey = GlobalKey<ChildClassroomQrCardState>();
  bool _isLoading = true;
  String? _error;
  ParentChildDetail? _detail;

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
        _detail = detail;
        _isLoading = false;
      });
      _qrCardKey.currentState?.reload();
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

  void _onChildSaved(ParentChild child) {
    final detail = _detail;
    if (detail == null) {
      return;
    }
    setState(() {
      _detail = ParentChildDetail(
        child: child,
        homeworkCount: detail.homeworkCount,
        education: detail.education,
      );
    });
  }

  String _childDisplayName(ParentChild child) {
    final lines = childDisplayNameLines(child);
    return '${lines.lastName} ${lines.givenName}'.trim();
  }

  String _title(ParentChild child) => _childDisplayName(child);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final child = _detail?.child;

    return ParentScaffold(
      title: child != null ? _title(child) : l10n.parentAccountChildSummary,
      body: _buildBody(l10n),
    );
  }

  Widget _buildBody(dynamic l10n) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: ParentColors.shell));
    }

    if (_error != null || _detail == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _error ?? l10n.parentLoadChildrenFailed,
            textAlign: TextAlign.center,
            style: const TextStyle(color: ParentColors.inkMuted),
          ),
        ),
      );
    }

    final detail = _detail!;
    final child = detail.child;
    final tokens = childCardColorTokens(child.cardColor);

    return AccountDeskShell(
      refreshIndicator: _load,
      children: [
        EditChildFormPanel(
          key: ValueKey(child.id),
          childId: widget.childId,
          initialChild: child,
          onSaved: _onChildSaved,
        ),
        ...childEducationProfileCards(
          context: context,
          child: child,
          education: detail.education,
        ),
        ChildClassroomQrCard(
          key: _qrCardKey,
          childId: widget.childId,
          childName: _childDisplayName(child),
          tokens: tokens,
        ),
        DeleteChildPanel(
          childId: widget.childId,
          tokens: tokens,
          hasActiveNetworkEnrollment: detail.hasActiveNetworkEnrollment,
        ),
      ],
    );
  }
}
