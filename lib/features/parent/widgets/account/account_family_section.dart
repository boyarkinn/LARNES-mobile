import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:larnes_mobile/core/api/guardians_api.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/parent/widgets/account/account_widgets.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

class AccountFamilySection extends StatefulWidget {
  const AccountFamilySection({
    super.key,
    required this.snapshot,
    required this.onChanged,
  });

  final GuardiansSnapshot? snapshot;
  final Future<void> Function() onChanged;

  @override
  State<AccountFamilySection> createState() => _AccountFamilySectionState();
}

class _AccountFamilySectionState extends State<AccountFamilySection> {
  bool _isPending = false;
  String? _error;

  String _relationshipLabel(dynamic l10n, String relationship) {
    switch (relationship) {
      case 'father':
        return l10n.parentGuardiansRelationshipFather;
      case 'grandmother':
        return l10n.parentGuardiansRelationshipGrandmother;
      case 'grandfather':
        return l10n.parentGuardiansRelationshipGrandfather;
      case 'mother':
      default:
        return l10n.parentGuardiansRelationshipMother;
    }
  }

  Future<void> _createInvite() async {
    setState(() {
      _isPending = true;
      _error = null;
    });

    try {
      final locale = LocaleScope.of(context).localeCode;
      final invite = await AuthScope.of(context).guardiansApi.createInvite(locale: locale);
      try {
        await Clipboard.setData(ClipboardData(text: invite.inviteUrl));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.parentGuardiansInviteCopied)),
          );
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.parentGuardiansInviteCreated)),
          );
        }
      }
      await widget.onChanged();
    } on GuardiansApiException catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
      }
    } finally {
      if (mounted) {
        setState(() => _isPending = false);
      }
    }
  }

  Future<void> _confirmRevoke(String inviteId) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.parentGuardiansConfirmRevokeTitle),
        content: Text(l10n.parentGuardiansConfirmRevokeMessage),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.parentAccountCancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.parentGuardiansRevokeInvite)),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _isPending = true;
      _error = null;
    });

    try {
      final locale = LocaleScope.of(context).localeCode;
      await AuthScope.of(context).guardiansApi.revokeInvite(inviteId: inviteId, locale: locale);
      await widget.onChanged();
    } on GuardiansApiException catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
      }
    } finally {
      if (mounted) {
        setState(() => _isPending = false);
      }
    }
  }

  Future<void> _confirmRemove(FamilyGuardian guardian) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(guardian.isSelf ? l10n.parentGuardiansConfirmLeaveTitle : l10n.parentGuardiansConfirmRemoveTitle),
        content: Text(
          guardian.isSelf ? l10n.parentGuardiansConfirmLeaveMessage : l10n.parentGuardiansConfirmRemoveMessage,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.parentAccountCancel)),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(guardian.isSelf ? l10n.parentGuardiansLeaveFamily : l10n.parentGuardiansRemove),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _isPending = true;
      _error = null;
    });

    try {
      final locale = LocaleScope.of(context).localeCode;
      await AuthScope.of(context).guardiansApi.removeGuardian(
            targetUserId: guardian.userId,
            locale: locale,
          );
      if (guardian.isSelf) {
        await AuthScope.of(context).refreshFamilySetup(locale: locale);
        if (!mounted) {
          return;
        }
        context.go('/parent/family-setup');
        return;
      }
      await widget.onChanged();
    } on GuardiansApiException catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
      }
    } finally {
      if (mounted) {
        setState(() => _isPending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final snapshot = widget.snapshot;

    if (snapshot == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text(_error!, style: const TextStyle(color: Color(0xFFB91C1C))),
          ),
        if (snapshot.guardians.isEmpty)
          AccountEmptyText(text: l10n.parentGuardiansEmpty)
        else
          for (var i = 0; i < snapshot.guardians.length; i++) ...[
            if (i > 0) const AccountDivider(),
            AccountChildRow(
              name: snapshot.guardians[i].fullName,
              meta: '${_relationshipLabel(l10n, snapshot.guardians[i].relationship)}${snapshot.guardians[i].isSelf ? ' · ${l10n.parentGuardiansYou}' : ''}',
              onTap: _isPending ? () {} : () => _confirmRemove(snapshot.guardians[i]),
            ),
          ],
        for (var i = 0; i < snapshot.pendingInvites.length; i++) ...[
          const AccountDivider(),
          AccountChildRow(
            name: l10n.parentGuardiansPendingInviteLabel,
            meta: l10n.parentGuardiansPendingInviteStatus,
            onTap: _isPending ? () {} : () => _confirmRevoke(snapshot.pendingInvites[i].id),
          ),
        ],
        if (snapshot.guardians.isNotEmpty || snapshot.pendingInvites.isNotEmpty) const AccountDivider(),
        AccountLinkRow(
          label: l10n.parentGuardiansInviteFamilyMember,
          enabled: !_isPending,
          onTap: _isPending ? null : _createInvite,
        ),
      ],
    );
  }
}
