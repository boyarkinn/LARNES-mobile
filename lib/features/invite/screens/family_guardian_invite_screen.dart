import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';
import 'package:larnes_mobile/core/api/family_invites_api.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/core/routing/home_path_mapper.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_buttons.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_scaffold.dart';
import 'package:larnes_mobile/features/parent/widgets/account/account_widgets.dart';
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
      return AuthScaffold(
        title: l10n.inviteFamilyGuardianTitle,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null && _invitation == null) {
      return AuthScaffold(
        title: l10n.inviteInvalidTitle,
        child: Text(_error!, style: const TextStyle(color: ParentColors.inkMuted)),
      );
    }

    if (!auth.isAuthenticated) {
      return AuthScaffold(
        title: l10n.inviteFamilyGuardianLoginTitle,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.inviteFamilyGuardianLoginSubtitle,
              style: GoogleFonts.onest(fontSize: 14, color: ParentColors.inkMuted, height: 1.45),
            ),
            const SizedBox(height: 16),
            AuthPrimaryButton(
              label: l10n.loginTitle,
              onPressed: () => context.go('/login?from=${Uri.encodeComponent(redirectPath)}'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.go('/register'),
              child: Text(l10n.inviteFamilyGuardianRegister),
            ),
          ],
        ),
      );
    }

    final user = auth.user!;

    if (!isParentAccount(user.accountType)) {
      return AuthScaffold(
        title: l10n.inviteFamilyGuardianWrongAccountTitle,
        child: Text(
          l10n.inviteFamilyGuardianWrongAccountSubtitle,
          style: GoogleFonts.onest(fontSize: 14, color: ParentColors.inkMuted, height: 1.45),
        ),
      );
    }

    final invitation = _invitation!;

    return AuthScaffold(
      title: l10n.inviteFamilyGuardianTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.inviteFamilyGuardianSubtitle,
            style: GoogleFonts.onest(fontSize: 14, color: ParentColors.inkMuted, height: 1.45),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ParentColors.parchment,
              borderRadius: BorderRadius.circular(ParentRadii.card),
            ),
            child: Text(
              '${l10n.inviteFamilyGuardianInviterLabel}: ${invitation.inviter.fullName}',
              style: GoogleFonts.onest(fontSize: 14, color: ParentColors.ink),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Color(0xFFB91C1C))),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isPending ? null : _decline,
                  child: Text(l10n.inviteFamilyGuardianDecline),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AccountPrimaryButton(
                  label: l10n.inviteFamilyGuardianAccept,
                  isLoading: _isPending,
                  onPressed: _accept,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
