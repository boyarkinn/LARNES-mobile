import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:larnes_mobile/core/api/parent_api.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/auth/auth_session.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/core/routing/home_path_mapper.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_buttons.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_invite_header.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_invite_widgets.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_text_field.dart';
import 'package:larnes_mobile/features/parent/models/parent_child.dart';
import 'package:larnes_mobile/features/parent/models/parent_lesson_invite.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

class LessonInviteScreen extends StatefulWidget {
  const LessonInviteScreen({super.key, required this.token});

  final String token;

  @override
  State<LessonInviteScreen> createState() => _LessonInviteScreenState();
}

class _LessonInviteScreenState extends State<LessonInviteScreen>
    with WidgetsBindingObserver {
  static const _guestPollInterval = Duration(seconds: 3);

  AuthSession? _auth;
  bool _isLoading = true;
  String? _error;
  String? _peekStatus;
  ParentLessonInvite? _invite;
  String? _joiningChildId;
  bool _guestJoined = false;
  bool _joiningGuest = false;
  Timer? _guestPoll;

  String get _redirectPath =>
      '/invite/lesson?token=${Uri.encodeComponent(widget.token)}';

  String get _guestRoomPath =>
      '/invite/lesson/room?token=${Uri.encodeComponent(widget.token)}';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _load();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = AuthScope.of(context);
    if (identical(_auth, auth)) {
      return;
    }

    _auth?.removeListener(_onAuthChanged);
    _auth = auth;
    auth.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    _guestPoll?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _auth?.removeListener(_onAuthChanged);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted && _guestJoined) {
      unawaited(_pollGuest());
    }
  }

  void _onAuthChanged() {
    if (!mounted) {
      return;
    }

    if (_auth?.isAuthenticated == true &&
        _invite == null &&
        _peekStatus == 'active' &&
        !_isLoading) {
      _stopGuestPoll();
      _load();
    }
  }

  void _stopGuestPoll() {
    _guestPoll?.cancel();
    _guestPoll = null;
  }

  void _ensureGuestPoll() {
    _guestPoll ??= Timer.periodic(_guestPollInterval, (_) {
      if (!mounted || !_guestJoined) {
        return;
      }

      unawaited(_pollGuest());
    });
  }

  Future<void> _load() async {
    if (widget.token.isEmpty) {
      setState(() {
        _error = context.l10n.inviteInvalid;
        _peekStatus = 'invalid';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final locale = LocaleScope.read(context).localeCode;
    final auth = AuthScope.of(context);

    try {
      final peek = await auth.parentApi.peekLessonInvite(
        token: widget.token,
        locale: locale,
      );
      if (!mounted) {
        return;
      }

      if (peek != 'active') {
        _stopGuestPoll();
        setState(() {
          _peekStatus = peek;
          _invite = null;
          _guestJoined = false;
          _isLoading = false;
        });
        return;
      }

      if (!auth.isAuthenticated || !isParentAccount(auth.user?.accountType)) {
        if (!auth.isAuthenticated) {
          final guest = await auth.lessonInviteGuestApi.fetchRoom(
            token: widget.token,
            locale: locale,
            poll: true,
          );
          if (!mounted) {
            return;
          }

          if (guest?.isOk == true) {
            context.go(_guestRoomPath);
            return;
          }

          final waiting = guest?.status == 'guest';
          setState(() {
            _peekStatus = peek;
            _invite = null;
            _guestJoined = waiting;
            _isLoading = false;
          });
          if (waiting) {
            _ensureGuestPoll();
          } else {
            _stopGuestPoll();
          }
          return;
        }

        setState(() {
          _peekStatus = peek;
          _invite = null;
          _guestJoined = false;
          _isLoading = false;
        });
        return;
      }

      _stopGuestPoll();
      final invite = await auth.parentApi.fetchLessonInvite(
        token: widget.token,
        locale: locale,
      );
      if (!mounted) {
        return;
      }

      setState(() {
        _peekStatus = invite.state;
        _invite = invite;
        _guestJoined = false;
        _isLoading = false;
      });
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
          _error = context.l10n.requestFailed;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pollGuest() async {
    try {
      final guest = await AuthScope.of(context).lessonInviteGuestApi.fetchRoom(
            token: widget.token,
            locale: LocaleScope.read(context).localeCode,
            poll: true,
          );
      if (!mounted) {
        return;
      }

      if (guest?.isOk == true) {
        _stopGuestPoll();
        context.go(_guestRoomPath);
        return;
      }

      if (guest?.status == 'left') {
        _stopGuestPoll();
        setState(() {
          _guestJoined = false;
        });
        return;
      }

      if (guest?.status == 'expired' || guest?.status == 'invalid') {
        _stopGuestPoll();
        setState(() {
          _peekStatus = guest!.status;
          _guestJoined = false;
        });
      }
    } catch (_) {
      return;
    }
  }

  Future<void> _joinGuest() async {
    if (_joiningGuest || _guestJoined) {
      return;
    }

    setState(() {
      _joiningGuest = true;
      _error = null;
    });

    try {
      await AuthScope.of(context).lessonInviteGuestApi.join(
            token: widget.token,
            locale: LocaleScope.read(context).localeCode,
          );
      if (!mounted) {
        return;
      }

      setState(() {
        _joiningGuest = false;
        _guestJoined = true;
      });
      _ensureGuestPoll();
      unawaited(_pollGuest());
    } on ParentApiException catch (error) {
      if (mounted) {
        setState(() {
          _joiningGuest = false;
          _error = error.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _joiningGuest = false;
          _error = context.l10n.parentLiveLessonJoinFailed;
        });
      }
    }
  }

  Future<void> _openRoom(String childId) async {
    context.go('/parent/$childId/lesson');
  }

  Future<void> _join(ParentLessonInviteChild child) async {
    if (_joiningChildId != null) {
      return;
    }

    if (child.presence == ParentLiveLessonPresence.classroom) {
      return;
    }

    if (child.presence == ParentLiveLessonPresence.online) {
      await _openRoom(child.childId);
      return;
    }

    setState(() {
      _joiningChildId = child.childId;
      _error = null;
    });

    try {
      final locale = LocaleScope.read(context).localeCode;
      await AuthScope.of(context).parentApi.joinLessonInvite(
            childId: child.childId,
            locale: locale,
            token: widget.token,
          );
      if (!mounted) {
        return;
      }

      await _openRoom(child.childId);
    } on ParentApiException catch (error) {
      if (mounted) {
        setState(() {
          _joiningChildId = null;
          _error = error.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _joiningChildId = null;
          _error = context.l10n.parentLiveLessonJoinFailed;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final auth = AuthScope.of(context);

    if (_isLoading) {
      return AuthInviteShell(
        title: l10n.inviteLessonTitle,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_peekStatus == 'invalid' ||
        (_error != null && _invite == null && _peekStatus != 'active')) {
      return AuthInviteShell(
        title: l10n.inviteInvalidTitle,
        child: AuthErrorBanner(message: _error ?? l10n.inviteInvalid),
      );
    }

    if (_peekStatus == 'expired') {
      return AuthInviteShell(
        title: l10n.inviteLessonExpiredTitle,
        child: AuthErrorBanner(message: l10n.inviteLessonExpiredMessage),
      );
    }

    if (!auth.isAuthenticated) {
      return AuthInviteShell(
        title: l10n.inviteLessonLoginTitle,
        subtitle: l10n.inviteLessonLoginSubtitle,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null) ...[
              AuthErrorBanner(message: _error!),
              const SizedBox(height: 12),
            ],
            AuthInviteLoginGate(
              loginLabel: l10n.inviteLessonLogin,
              onLogin: () =>
                  context.go('/login?from=${Uri.encodeComponent(_redirectPath)}'),
              registerLead: l10n.loginNoAccount,
              registerLabel: l10n.inviteLessonRegister,
              onRegister: () => context.go('/register'),
              extra: _guestJoined
                  ? Text(
                      l10n.inviteLessonGuestJoined,
                      textAlign: TextAlign.center,
                    )
                  : AuthSecondaryButton(
                      label: _joiningGuest
                          ? l10n.inviteLessonContinuingAsGuest
                          : l10n.inviteLessonContinueAsGuest,
                      isLoading: _joiningGuest,
                      onPressed: _joiningGuest ? null : _joinGuest,
                    ),
            ),
          ],
        ),
      );
    }

    if (!isParentAccount(auth.user?.accountType)) {
      return AuthInviteShell(
        title: l10n.inviteLessonWrongAccountTitle,
        subtitle: l10n.inviteLessonWrongAccountSubtitle,
        child: const SizedBox.shrink(),
      );
    }

    final invite = _invite;
    if (invite == null || !invite.isActive) {
      return AuthInviteShell(
        title: l10n.inviteLessonTitle,
        child: AuthErrorBanner(message: _error ?? l10n.inviteInvalid),
      );
    }

    return AuthInviteShell(
      title: l10n.inviteLessonTitle,
      subtitle: l10n.inviteLessonSubtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_error != null) ...[
            AuthErrorBanner(message: _error!),
            const SizedBox(height: 12),
          ],
          if (invite.children.isEmpty)
            Text(
              l10n.inviteLessonNoChildren,
              textAlign: TextAlign.center,
            )
          else
            for (final child in invite.children) ...[
              _InviteChildAction(
                child: child,
                isJoining: _joiningChildId == child.childId,
                joinLabel: l10n.inviteLessonJoinChild(child.displayName),
                joiningLabel: l10n.inviteLessonJoining,
                openLabel: l10n.inviteLessonOpenChild(child.displayName),
                atDeskLabel: l10n.inviteLessonAtDesk,
                onPressed: _joiningChildId == null
                    ? () {
                        _join(child);
                      }
                    : null,
              ),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

class _InviteChildAction extends StatelessWidget {
  const _InviteChildAction({
    required this.child,
    required this.isJoining,
    required this.joinLabel,
    required this.joiningLabel,
    required this.openLabel,
    required this.atDeskLabel,
    required this.onPressed,
  });

  final ParentLessonInviteChild child;
  final bool isJoining;
  final String joinLabel;
  final String joiningLabel;
  final String openLabel;
  final String atDeskLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    if (child.presence == ParentLiveLessonPresence.classroom) {
      return AuthInviteContextCard(
        label: child.displayName,
        value: atDeskLabel,
      );
    }

    final online = child.presence == ParentLiveLessonPresence.online;
    return AuthPrimaryButton(
      label: isJoining ? joiningLabel : (online ? openLabel : joinLabel),
      isLoading: isJoining,
      useWebAuthStyle: true,
      onPressed: onPressed,
    );
  }
}
