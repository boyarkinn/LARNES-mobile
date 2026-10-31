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

class LiveLessonRoomScreen extends StatefulWidget {
  const LiveLessonRoomScreen({super.key, required this.childId});

  final String childId;

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
    if (state == AppLifecycleState.resumed && mounted && !_leaving) {
      unawaited(_pollRoom());
    }
  }

  String get _locale => LocaleScope.read(context).localeCode;

  ParentApi get _api => AuthScope.of(context).parentApi;

  void _ensurePoll() {
    _poll ??= Timer.periodic(_pollInterval, (_) {
      if (!mounted || _leaving) {
        return;
      }

      unawaited(_pollRoom());
    });
  }

  Future<void> _loadRoom() async {
    setState(() {
      _isLoading = _room == null;
      _loadError = null;
    });

    try {
      final room = await _api.fetchLiveLessonRoom(
        childId: widget.childId,
        locale: _locale,
      );
      if (!mounted) {
        return;
      }

      if (room.isGone) {
        _goPicker();
        return;
      }

      _applyRoom(room);
      _ensurePoll();
    } on ParentApiException catch (error) {
      if (!mounted) {
        return;
      }

      if (error.code == 'gone') {
        _goPicker();
        return;
      }

      setState(() {
        _loadError = error.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loadError = context.l10n.parentLiveLessonLoadFailed;
        _isLoading = false;
      });
    }
  }

  Future<void> _pollRoom() async {
    try {
      final poll = await _api.fetchLiveLessonRoom(
        childId: widget.childId,
        locale: _locale,
        poll: true,
      );
      if (!mounted || _leaving) {
        return;
      }

      if (poll.isGone) {
        _goPicker();
        return;
      }

      if (poll.isOk && poll.sessionId != _room?.sessionId) {
        await _loadRoom();
      }
    } on ParentApiException catch (error) {
      if (!mounted) {
        return;
      }

      if (error.code == 'gone') {
        _goPicker();
      }
    } catch (_) {
      return;
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
    if (_leaving) {
      return;
    }

    _leaving = true;
    _poll?.cancel();
    final api = _api;
    final locale = _locale;
    await _call.end();

    try {
      await api.leaveLiveLesson(childId: widget.childId, locale: locale);
    } catch (_) {
      // Web also leaves the room even if the action fails.
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
