import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';
import 'package:larnes_mobile/core/api/guardians_api.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/parent/widgets/account/account_widgets.dart';
import 'package:larnes_mobile/features/parent/widgets/parent_scaffold.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

class AccountGuardiansScreen extends StatefulWidget {
  const AccountGuardiansScreen({super.key});

  @override
  State<AccountGuardiansScreen> createState() => _AccountGuardiansScreenState();
}

class _AccountGuardiansScreenState extends State<AccountGuardiansScreen> {
  bool _isLoading = true;
  bool _isPending = false;
  String? _error;
  GuardiansSnapshot? _snapshot;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _load();
      }
    });
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
      final snapshot = await AuthScope.of(context).guardiansApi.fetchGuardians(locale: locale);
      if (!mounted) {
        return;
      }
      setState(() {
        _snapshot = snapshot;
        _isLoading = false;
        _error = null;
      });
    } on GuardiansApiException catch (error) {
      if (mounted) {
        setState(() {
          _error = error.message;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = context.l10n.requestFailed;
          _isLoading = false;
        });
      }
    }
  }

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
      await _load(silent: true);
    } on GuardiansApiException catch (error) {
      if (mounted) {
        setState(() {
          _error = error.message;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isPending = false);
      }
    }
  }

  Future<void> _revokeInvite(String inviteId) async {
    setState(() {
      _isPending = true;
      _error = null;
    });

    try {
      final locale = LocaleScope.of(context).localeCode;
      await AuthScope.of(context).guardiansApi.revokeInvite(inviteId: inviteId, locale: locale);
      await _load(silent: true);
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
      await _load(silent: true);
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

    return ParentScaffold(
      title: l10n.parentGuardiansTitle,
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
            ],
          ),
        ),
      );
    }

    final snapshot = _snapshot!;

    return AccountDeskShell(
      refreshIndicator: () => _load(silent: true),
      children: [
        AccountDeskCard(
          bandTitle: l10n.parentGuardiansSectionTitle,
          child: Column(
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
                  _GuardianRow(
                    guardian: snapshot.guardians[i],
                    meta: '${_relationshipLabel(l10n, snapshot.guardians[i].relationship)}${snapshot.guardians[i].isSelf ? ' · ${l10n.parentGuardiansYou}' : ''}',
                    actionLabel: snapshot.guardians[i].isSelf
                        ? l10n.parentGuardiansLeaveFamily
                        : l10n.parentGuardiansRemove,
                    onAction: _isPending ? null : () => _confirmRemove(snapshot.guardians[i]),
                  ),
                ],
              if (snapshot.pendingInvites.isNotEmpty) ...[
                const AccountDivider(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text(
                    l10n.parentGuardiansPendingInvitesTitle,
                    style: GoogleFonts.onest(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: ParentColors.inkMuted,
                    ),
                  ),
                ),
                for (var i = 0; i < snapshot.pendingInvites.length; i++) ...[
                  if (i > 0) const AccountDivider(),
                  _GuardianRow(
                    guardian: null,
                    meta: snapshot.pendingInvites[i].inviteUrl,
                    actionLabel: l10n.parentGuardiansRevokeInvite,
                    onAction: _isPending ? null : () => _revokeInvite(snapshot.pendingInvites[i].id),
                  ),
                ],
              ],
              const AccountDivider(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: AccountPrimaryButton(
                  label: l10n.parentGuardiansInviteGuardian,
                  isLoading: _isPending,
                  onPressed: _createInvite,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GuardianRow extends StatelessWidget {
  const _GuardianRow({
    required this.guardian,
    required this.meta,
    required this.actionLabel,
    required this.onAction,
  });

  final FamilyGuardian? guardian;
  final String meta;
  final String actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AccountDeskMetrics.rowPadding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (guardian != null)
                  Text(
                    guardian!.fullName,
                    style: GoogleFonts.onest(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: ParentColors.ink,
                    ),
                  ),
                Text(
                  meta,
                  style: GoogleFonts.onest(
                    fontSize: guardian == null ? 13 : 13,
                    fontWeight: FontWeight.w500,
                    color: ParentColors.inkMuted,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onAction,
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}
