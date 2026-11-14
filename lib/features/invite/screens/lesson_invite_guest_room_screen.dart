import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:larnes_mobile/core/api/parent_api.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/messenger/messenger_room.dart';
import 'package:larnes_mobile/features/messenger/messenger_scope.dart';
import 'package:larnes_mobile/features/parent/models/parent_live_lesson_room.dart';
import 'package:larnes_mobile/features/parent/widgets/lesson_call_stage.dart';
import 'package:larnes_mobile/features/parent/widgets/live_lesson_waiting_view.dart';
import 'package:larnes_mobile/features/parent/widgets/parent_player_shell.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';
import 'package:uuid/uuid.dart';

class LessonInviteGuestRoomScreen extends StatefulWidget {
  const LessonInviteGuestRoomScreen({super.key, required this.token});

  final String token;

  @override
  State<LessonInviteGuestRoomScreen> createState() =>
      _LessonInviteGuestRoomScreenState();
}

class _LessonInviteGuestRoomScreenState
    extends State<LessonInviteGuestRoomScreen>
    with WidgetsBindingObserver {
  static const _pollInterval = Duration(seconds: 3);

  bool _isLoading = true;
  String? _loadError;
  ParentLiveLessonRoomState? _room;
  bool _leaving = false;
  final _call = LessonCallStageHandle();
  bool _exited = false;
  bool _reading = false;
  final _connectionId = const Uuid().v4();
  Timer? _poll;

  String get _exitPath =>
      '/invite/lesson/left?token=${Uri.encodeComponent(widget.token)}';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(_loadRoom());
      }
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_loadRoom(poll: _room != null));
    }
  }

  String get _locale => LocaleScope.read(context).localeCode;

  void _ensurePoll() {
    _poll ??= Timer.periodic(_pollInterval, (_) {
      unawaited(_loadRoom(poll: true));
    });
  }

  bool get _active => mounted && !_leaving && !_exited;

  Future<void> _loadRoom({bool poll = false}) async {
    if (!_active || _reading) return;
    _reading = true;
    if (!poll) {
      setState(() {
        _isLoading = _room == null;
        _loadError = null;
      });
    }

    try {
      final api = AuthScope.of(context).lessonInviteGuestApi;
      var room = await api.fetchRoom(
        token: widget.token,
        connectionId: _connectionId,
        locale: _locale,
        poll: poll,
      );
      if (!_active) return;
      if (poll && room != null && room.isOk) {
        if (room.sessionId == _room?.sessionId &&
            room.commandSeq == _room?.commandSeq) {
          return;
        }
        room = await api.fetchRoom(
          token: widget.token,
          connectionId: _connectionId,
          locale: _locale,
        );
        if (!_active) return;
      }
      if (room == null || !room.isOk) {
        _showExit();
        return;
      }
      _applyRoom(room);
      _ensurePoll();
    } on ParentApiException catch (error) {
      if (_active && !poll) {
        setState(() {
          _loadError = error.message;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (_active && !poll) {
        setState(() {
          _loadError = context.l10n.parentLiveLessonLoadFailed;
          _isLoading = false;
        });
      }
    } finally {
      _reading = false;
    }
  }

  void _applyRoom(ParentLiveLessonRoomState room) {
    setState(() {
      _room = room;
      _isLoading = false;
      _loadError = null;
    });
  }

  void _showExit() {
    if (!mounted || _exited) {
      return;
    }

    _exited = true;
    _poll?.cancel();
    context.go(_exitPath);
  }

  Future<void> _leaveLesson() async {
    if (!_active) {
      return;
    }

    _leaving = true;
    _poll?.cancel();
    final api = AuthScope.of(context).lessonInviteGuestApi;
    final locale = _locale;
    try {
      await Future.wait([
        api.leave(
          token: widget.token,
          connectionId: _connectionId,
          sessionId: _room?.sessionId,
          locale: locale,
        ),
        _call.end(),
      ]);
    } catch (_) {
      // Once polling stops, a dropped leave request expires on the server.
    } finally {
      if (mounted) {
        unawaited(
          MessengerRooms.clearGuest().catchError((Object error) {
            debugPrint('Could not clear the lesson guest chat cache: $error');
          }),
        );
        _showExit();
      }
    }
  }

  MessengerScope? _chatScope(ParentLiveLessonRoomState room) {
    final sessionId = room.sessionId?.trim() ?? '';
    if (sessionId.isEmpty) return null;
    return MessengerScope.guest(
      admissionId: room.admissionId,
      childId: room.childId,
      lessonSessionId: sessionId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }

        unawaited(_leaveLesson());
      },
      child: _room == null
          ? _buildBody(l10n)
          : LessonCallStage(
              workspaceFormat: _room!.workspaceFormat,
              lessonSessionId: _room!.sessionId,
              body: null,
              childId: _room!.childId ?? '',
              handle: _call,
              inviteToken: widget.token,
              messenger: _chatScope(_room!),
              onLeave: () {
                unawaited(_leaveLesson());
              },
              trainerOpen: false,
            ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_isLoading && _room == null) {
      return const ParentPlayerLoading();
    }

    if (_loadError != null && _room == null) {
      return ParentPlayerError(
        message: _loadError!,
        retryLabel: l10n.continueButton,
        onRetry: () {
          unawaited(_loadRoom());
        },
      );
    }

    final room = _room;
    if (room == null) {
      return const ParentPlayerLoading();
    }

    return LiveLessonWaitingView(
      waiting: room.waiting,
      untitledLabel: l10n.parentLiveLessonUntitled,
      continueLabel: l10n.parentHomeworkPlayMenuContinue,
      exitLabel: l10n.parentHomeworkPlayExit,
      waitingLabel: l10n.parentLiveLessonWaitingTitle,
      onLeave: () {
        unawaited(_leaveLesson());
      },
    );
  }
}
