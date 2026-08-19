import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:larnes_mobile/core/api/family_invites_api.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/core/routing/home_path_mapper.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_invite_header.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_invite_widgets.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_text_field.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

class FamilyJoinRequestInviteScreen extends StatefulWidget {
  const FamilyJoinRequestInviteScreen({super.key, required this.token});

  final String token;

  @override
  State<FamilyJoinRequestInviteScreen> createState() => _FamilyJoinRequestInviteScreenState();
}

class _FamilyJoinRequestInviteScreenState extends State<FamilyJoinRequestInviteScreen> {
  bool _isLoading = true;
  bool _isPending = false;
  String? _error;
  FamilyJoinRequestInvitation? _invitation;

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
    if (widget.token.isEmpty) {
      setState(() {
        _error = context.l10n.inviteInvalid;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final locale = LocaleScope.read(context).localeCode;
      final invitation = await AuthScope.of(context).familyInvitesApi.fetchJoinRequest(
            token: widget.token,
            locale: locale,
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _invitation = invitation;
        _isLoading = false;
      });
    } on FamilyInvitesApiException catch (error) {
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

  Future<void> _accept() => _mutate(
        () => AuthScope.of(context).familyInvitesApi.acceptJoinRequest(
              token: widget.token,
              locale: LocaleScope.of(context).localeCode,
            ),
      );

  Future<void> _decline() => _mutate(
        () => AuthScope.of(context).familyInvitesApi.declineJoinRequest(
              token: widget.token,
              locale: LocaleScope.of(context).localeCode,
            ),
      );

  Future<void> _mutate(Future<void> Function() action) async {
    setState(() {
      _isPending = true;
      _error = null;
    });

    try {
      await action();
      if (!mounted) {
        return;
      }
      context.go('/parent');
    } on FamilyInvitesApiException catch (error) {
      if (mounted) {
        setState(() {
          _error = error.message;
          _isPending = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = context.l10n.requestFailed;
          _isPending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final auth = AuthScope.of(context);
    final redirectPath = '/invite/family-join-request?token=${Uri.encodeComponent(widget.token)}';

    if (_isLoading) {
      return AuthInviteShell(
        title: l10n.inviteFamilyJoinRequestTitle,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null && _invitation == null) {
      return AuthInviteShell(
        title: l10n.inviteInvalidTitle,
        child: AuthErrorBanner(message: _error!),
      );
    }

    if (!auth.isAuthenticated) {
      return AuthInviteShell(
        title: l10n.inviteFamilyJoinRequestLoginTitle,
        subtitle: l10n.inviteFamilyJoinRequestLoginSubtitle,
        child: AuthInviteLoginGate(
          loginLabel: l10n.signInButton,
          onLogin: () => context.go('/login?from=${Uri.encodeComponent(redirectPath)}'),
          registerLead: l10n.loginNoAccount,
          registerLabel: l10n.inviteFamilyJoinRequestRegister,
          onRegister: () => context.go('/register'),
        ),
      );
    }

    final user = auth.user!;
    final invitation = _invitation!;

    if (!isParentAccount(user.accountType)) {
      return AuthInviteShell(
        title: l10n.inviteFamilyJoinRequestWrongAccountTitle,
        subtitle: l10n.inviteFamilyJoinRequestWrongAccountSubtitle,
        child: const SizedBox.shrink(),
      );
    }

    if (user.id == invitation.requester.userId) {
      return AuthInviteShell(
        title: l10n.inviteFamilyJoinRequestOwnRequestTitle,
        subtitle: l10n.inviteFamilyJoinRequestOwnRequestSubtitle,
        child: const SizedBox.shrink(),
      );
    }

    return AuthInviteShell(
      title: l10n.inviteFamilyJoinRequestTitle,
      subtitle: l10n.inviteFamilyJoinRequestSubtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthInviteContextCard(
            label: l10n.inviteFamilyJoinRequestRequesterLabel,
            value: invitation.requester.fullName,
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            AuthErrorBanner(message: _error!),
          ],
          const SizedBox(height: 16),
          AuthInviteActions(
            declineLabel: l10n.inviteFamilyJoinRequestDecline,
            acceptLabel: l10n.inviteFamilyJoinRequestAccept,
            isLoading: _isPending,
            onDecline: _isPending ? null : _decline,
            onAccept: _isPending ? null : _accept,
          ),
        ],
      ),
    );
  }
}
