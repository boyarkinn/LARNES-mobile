import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:larnes_mobile/core/api/parent_api.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/parent/theme/child_card_colors.dart';
import 'package:larnes_mobile/features/parent/widgets/account/account_widgets.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

/// Delete child block on profile (web `DeleteChildForm`).
class DeleteChildPanel extends StatefulWidget {
  const DeleteChildPanel({
    super.key,
    required this.childId,
    required this.tokens,
    this.hasActiveNetworkEnrollment = false,
  });

  final String childId;
  final ChildCardColorTokens tokens;
  final bool hasActiveNetworkEnrollment;

  @override
  State<DeleteChildPanel> createState() => _DeleteChildPanelState();
}

class _DeleteChildPanelState extends State<DeleteChildPanel> {
  bool _isDeleting = false;
  String? _error;

  Future<void> _delete() async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.parentAccountDeleteChildTitle),
        content: Text(
          widget.hasActiveNetworkEnrollment
              ? l10n.parentAccountDeleteChildMessageActiveNetwork
              : l10n.parentAccountDeleteChildMessage,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.parentAccountCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.parentAccountDeleteChildConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _isDeleting = true;
      _error = null;
    });

    try {
      final locale = LocaleScope.of(context).localeCode;
      await AuthScope.of(context).parentApi.deleteChild(widget.childId, locale: locale);
      if (!mounted) {
        return;
      }
      AuthScope.of(context).notifyParentDataChanged();
      context.go('/parent');
    } on ParentApiException catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = context.l10n.parentDeleteChildFailed);
      }
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AccountDeskCard(
      tokens: widget.tokens,
      child: Padding(
        padding: AccountDeskMetrics.formPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null) ...[
              Text(
                _error!,
                style: TextStyle(color: Colors.red.shade700, fontSize: 14),
              ),
              const SizedBox(height: 12),
            ],
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade700,
                side: BorderSide(color: Colors.red.shade200),
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: _isDeleting ? null : _delete,
              child: _isDeleting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.parentAccountDeleteChildConfirm),
            ),
          ],
        ),
      ),
    );
  }
}
