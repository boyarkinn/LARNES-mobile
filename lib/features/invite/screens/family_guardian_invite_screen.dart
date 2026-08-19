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

class FamilyGuardianInviteScreen extends StatefulWidget {
  const FamilyGuardianInviteScreen({super.key, required this.token});

  final String token;

  @override
  State<FamilyGuardianInviteScreen> createState() => _FamilyGuardianInviteScreenState();
}

class _FamilyGuardianInviteScreenState extends State<FamilyGuardianInviteScreen> {
  bool _isLoading = true;
  bool _isPending = false;
  String? _error;
  FamilyGuardianInvitation? _invitation;

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
      final invitation = await AuthScope.of(context).familyInvitesApi.fetchGuardianInvite(
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

  Future<void> _accept() async {
    setState(() {
      _isPending = true;
      _error = null;
    });

    try {
      final locale = LocaleScope.of(context).localeCode;
      final auth = AuthScope.of(context);
      await auth.familyInvitesApi.acceptGuardianInvite(token: widget.token, locale: locale);
      await auth.refreshFamilySetup(locale: locale);
      if (!mounted) {
        return;
      }
      context.go('/parent');
    } on FamilyInvitesApiException catch (error) {
      if (error.code == 'name_collision' && mounted) {
        final query =
            'token=${Uri.encodeComponent(widget.token)}&kind=family-guardian-invite';
        context.go('/parent/family-join-dedup?$query');
        return;
      }
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

  Future<void> _decline() async {
    setState(() {
      _isPending = true;
      _error = null;
    });

    try {
      final locale = LocaleScope.of(context).localeCode;
      await AuthScope.of(context).familyInvitesApi.declineGuardianInvite(
            token: widget.token,
            locale: locale,
          );
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
    final redirectPath = '/invite/family-guardian?token=${Uri.encodeComponent(widget.token)}';

    if (_isLoading) {
      return AuthInviteShell(
        title: l10n.inviteFamilyGuardianTitle,
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
        title: l10n.inviteFamilyGuardianLoginTitle,
        subtitle: l10n.inviteFamilyGuardianLoginSubtitle,
        child: AuthInviteLoginGate(
          loginLabel: l10n.signInButton,
          onLogin: () => context.go('/login?from=${Uri.encodeComponent(redirectPath)}'),
          registerLead: l10n.loginNoAccount,
          registerLabel: l10n.inviteFamilyGuardianRegister,
          onRegister: () => context.go('/register'),
        ),
      );
    }

    final user = auth.user!;

    if (!isParentAccount(user.accountType)) {
      return AuthInviteShell(
        title: l10n.inviteFamilyGuardianWrongAccountTitle,
        subtitle: l10n.inviteFamilyGuardianWrongAccountSubtitle,
        child: const SizedBox.shrink(),
      );
    }

    final invitation = _invitation!;

    return AuthInviteShell(
      title: l10n.inviteFamilyGuardianTitle,
      subtitle: l10n.inviteFamilyGuardianSubtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthInviteContextCard(
            label: l10n.inviteFamilyGuardianInviterLabel,
            value: invitation.inviter.fullName,
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            AuthErrorBanner(message: _error!),
          ],
          const SizedBox(height: 16),
          AuthInviteActions(
            declineLabel: l10n.inviteFamilyGuardianDecline,
            acceptLabel: l10n.inviteFamilyGuardianAccept,
            isLoading: _isPending,
            onDecline: _isPending ? null : _decline,
            onAccept: _isPending ? null : _accept,
          ),
        ],
      ),
    );
  }
}
