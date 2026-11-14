import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_buttons.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_invite_header.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

class LessonInviteExitScreen extends StatefulWidget {
  const LessonInviteExitScreen({super.key, required this.token});

  final String token;

  @override
  State<LessonInviteExitScreen> createState() => _LessonInviteExitScreenState();
}

class _LessonInviteExitScreenState extends State<LessonInviteExitScreen>
    with WidgetsBindingObserver {
  Timer? _timer;
  bool _checking = false;
  String? _status;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_checkStatus());
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _timer?.cancel();
    if (state == AppLifecycleState.resumed) unawaited(_checkStatus());
  }

  Future<void> _checkStatus() async {
    if (_checking || _status == 'expired' || _status == 'invalid') return;
    _checking = true;
    try {
      final status = await AuthScope.of(context).parentApi.peekLessonInvite(
        token: widget.token,
        locale: LocaleScope.read(context).localeCode,
      );
      if (mounted && status != _status) setState(() => _status = status);
    } catch (_) {
      // Retry a temporary connection failure without opening the lesson.
    } finally {
      _checking = false;
      final visible = WidgetsBinding.instance.lifecycleState;
      if (mounted &&
          (_status == null || _status == 'active') &&
          (visible == null || visible == AppLifecycleState.resumed)) {
        _timer?.cancel();
        _timer = Timer(const Duration(seconds: 5), _checkStatus);
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AuthInviteShell(
      claim: true,
      title: switch (_status) {
        'expired' => l10n.inviteLessonExpiredTitle,
        'invalid' => l10n.inviteInvalidTitle,
        _ => l10n.inviteLessonLeftTitle,
      },
      child: _status == 'active'
          ? AuthPrimaryButton(
              label: l10n.inviteLessonReturn,
              onPressed: () => context.go(
                '/invite/lesson?token=${Uri.encodeComponent(widget.token)}',
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
