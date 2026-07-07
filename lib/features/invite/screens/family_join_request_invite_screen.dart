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
      return AuthScaffold(
        title: l10n.inviteFamilyJoinRequestTitle,
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
        title: l10n.inviteFamilyJoinRequestLoginTitle,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.inviteFamilyJoinRequestLoginSubtitle,
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
              child: Text(l10n.inviteFamilyJoinRequestRegister),
            ),
          ],
        ),
      );
    }

    final user = auth.user!;
    final invitation = _invitation!;

    if (!isParentAccount(user.accountType)) {
      return AuthScaffold(
        title: l10n.inviteFamilyJoinRequestWrongAccountTitle,
        child: Text(
          l10n.inviteFamilyJoinRequestWrongAccountSubtitle,
          style: GoogleFonts.onest(fontSize: 14, color: ParentColors.inkMuted, height: 1.45),
        ),
      );
    }

    if (user.id == invitation.requester.userId) {
      return AuthScaffold(
        title: l10n.inviteFamilyJoinRequestOwnRequestTitle,
        child: Text(
          l10n.inviteFamilyJoinRequestOwnRequestSubtitle,
          style: GoogleFonts.onest(fontSize: 14, color: ParentColors.inkMuted, height: 1.45),
        ),
      );
    }

    return AuthScaffold(
      title: l10n.inviteFamilyJoinRequestTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.inviteFamilyJoinRequestSubtitle,
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
              '${l10n.inviteFamilyJoinRequestRequesterLabel}: ${invitation.requester.fullName}',
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
                  child: Text(l10n.inviteFamilyJoinRequestDecline),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AccountPrimaryButton(
                  label: l10n.inviteFamilyJoinRequestAccept,
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
