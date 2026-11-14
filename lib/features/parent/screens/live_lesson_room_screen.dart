import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:larnes_mobile/core/api/parent_api.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/messenger/messenger_scope.dart';
import 'package:larnes_mobile/features/parent/models/parent_live_lesson_room.dart';
import 'package:larnes_mobile/features/parent/widgets/lesson_call_stage.dart';
import 'package:larnes_mobile/features/parent/widgets/live_lesson_waiting_view.dart';
import 'package:larnes_mobile/features/parent/widgets/parent_player_shell.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';
import 'package:uuid/uuid.dart';

class LiveLessonRoomScreen extends StatefulWidget {
  const LiveLessonRoomScreen({
    super.key,
    required this.childId,
    this.sessionId,
  });

  final String childId;
  final String? sessionId;

  @override
  State<LiveLessonRoomScreen> createState() => _LiveLessonRoomScreenState();
}

class _LiveLessonRoomScreenState extends State<LiveLessonRoomScreen>
    with WidgetsBindingObserver {
  static const _pollInterval = Duration(seconds: 3);

  bool _isLoading = true;
  String? _loadError;
  ParentLiveLessonRoomState? _room;
  bool _leaving = false;
  bool _exited = false;
  bool _reading = false;
  Future<ParentLiveLessonRoomState>? _opening;
  final _connectionId = const Uuid().v4();
  Timer? _poll;
  final _call = LessonCallStageHandle();

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

  ParentApi get _api => AuthScope.of(context).parentApi;

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
      final sessionId = _room?.sessionId ?? widget.sessionId;
      final request = _api.fetchLiveLessonRoom(
        childId: widget.childId,
        locale: _locale,
        connectionId: _connectionId,
        sessionId: sessionId,
        poll: poll,
      );
      if (sessionId == null) _opening = request;
      var room = await request;
      if (!_active) return;
      if (poll && room.isOk) {
        if (room.sessionId == _room?.sessionId) return;
        room = await _api.fetchLiveLessonRoom(
          childId: widget.childId,
          locale: _locale,
          connectionId: _connectionId,
          sessionId: room.sessionId,
        );
        if (!_active) return;
      }
      if (room.isGone) {
        _goPicker();
        return;
      }
      _applyRoom(room);
      _ensurePoll();
    } on ParentApiException catch (error) {
      if (!_active) return;
      if (error.code == 'gone') {
        _goPicker();
      } else if (!poll) {
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
      _opening = null;
    }
  }

  MessengerScope? _chatScope(ParentLiveLessonRoomState room) {
    final sessionId = room.sessionId?.trim() ?? '';
    final accountId = AuthScope.of(context).user?.id ?? '';
    if (sessionId.isEmpty || accountId.isEmpty) return null;
    return MessengerScope.parent(
      intent: MessengerIntent.child,
      accountId: accountId,
      childId: widget.childId,
      lessonSessionId: sessionId,
    );
  }

  void _applyRoom(ParentLiveLessonRoomState room) {
    setState(() {
      _room = room;
      _isLoading = false;
      _loadError = null;
    });
  }

  void _goPicker() {
    if (!mounted || _exited) {
      return;
    }

    _exited = true;
    _poll?.cancel();

    if (context.canPop()) {
      context.pop();
      return;
    }

    context.go('/parent');
  }

  Future<void> _leaveLesson() async {
    if (!_active) {
      return;
    }

    _leaving = true;
    _poll?.cancel();
    final api = _api;
    final childId = widget.childId;
    final locale = _locale;
    try {
      var sessionId = _room?.sessionId ?? widget.sessionId;
      if (sessionId == null) {
        // A direct link can be closed before its first response names the lesson.
        final opening = _opening;
        _goPicker();
        sessionId = (await opening)?.sessionId;
        if (sessionId == null) return;
      }
      await Future.wait([
        api.leaveLiveLesson(
          childId: childId,
          connectionId: _connectionId,
          sessionId: sessionId,
          locale: locale,
        ),
        _call.end(),
      ]);
    } catch (_) {
      // Once polling stops, a dropped leave request expires on the server.
    } finally {
      _goPicker();
    }
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
              childId: widget.childId,
              handle: _call,
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
