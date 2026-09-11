import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:larnes_mobile/core/api/parent_api.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/parent/models/parent_live_lesson_room.dart';
import 'package:larnes_mobile/features/parent/widgets/live_lesson_waiting_view.dart';
import 'package:larnes_mobile/features/parent/widgets/parent_player_shell.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';
import 'package:larnes_mobile/trainers/runtime/trainer_play_shell.dart';
import 'package:larnes_mobile/trainers/runtime/trainer_player.dart';
import 'package:larnes_mobile/trainers/runtime/trainer_step_chrome.dart';

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
  int _stepIndex = 0;
  int? _dismissedSeq;
  bool _leaving = false;
  bool _exited = false;
  Timer? _poll;

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

  bool get _showingPlayer {
    final room = _room;
    return room != null &&
        room.hasPlayCommand &&
        _dismissedSeq != room.commandSeq;
  }

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

      if (poll.isOk && poll.commandSeq != (_room?.commandSeq ?? -1)) {
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

  void _applyRoom(ParentLiveLessonRoomState room) {
    final seqChanged = room.commandSeq != _room?.commandSeq;
    setState(() {
      _room = room;
      _isLoading = false;
      _loadError = null;
      if (seqChanged) {
        _stepIndex = room.snapshot?.currentStepIndex ?? 0;
      }
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

    try {
      await _api.leaveLiveLesson(childId: widget.childId, locale: _locale);
    } catch (_) {
      // Web also leaves the room even if the action fails.
    } finally {
      _goPicker();
    }
  }

  void _dismissPlayer() {
    final room = _room;
    if (room == null) {
      return;
    }

    setState(() {
      _dismissedSeq = room.commandSeq;
    });
  }

  void _advanceStep() {
    final snapshot = _room?.snapshot;
    if (snapshot == null) {
      return;
    }

    final nextStepIndex = _stepIndex + 1;
    if (nextStepIndex >= snapshot.steps.length) {
      _dismissPlayer();
      return;
    }

    setState(() {
      _stepIndex = nextStepIndex;
    });
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

        if (_showingPlayer) {
          _dismissPlayer();
          return;
        }

        unawaited(_leaveLesson());
      },
      child: _buildBody(l10n),
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

    if (_showingPlayer) {
      return _buildPlayer(l10n, room);
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

  Widget _buildPlayer(AppLocalizations l10n, ParentLiveLessonRoomState room) {
    final snapshot = room.snapshot!;
    final totalSteps = snapshot.steps.length;

    if (totalSteps == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _dismissPlayer();
        }
      });
      return const ParentPlayerLoading();
    }

    if (_stepIndex >= totalSteps) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _dismissPlayer();
        }
      });
      return const ParentPlayerLoading();
    }

    final step = snapshot.steps[_stepIndex];
    final isLast = _stepIndex >= totalSteps - 1;
    final isInteractive = isTrainerInteractive(step.trainerKey);

    return TrainerPlayShell(
      key: ValueKey(room.commandSeq),
      currentStep: _stepIndex + 1,
      totalSteps: totalSteps,
      menuContinueLabel: l10n.parentHomeworkPlayMenuContinue,
      menuExitLabel: l10n.parentHomeworkPlayExit,
      onExit: _dismissPlayer,
      child: TrainerPlayer(
        key: ValueKey(step.id),
        trainerKey: step.trainerKey,
        params: step.params,
        runtimeSnapshot: step.runtimeSnapshot,
        l10n: l10n,
        onComplete: isInteractive ? _advanceStep : null,
        stepChrome: TrainerStepChrome(
          finishLabel: l10n.parentHomeworkPlayFinish,
          isInteractive: isInteractive,
          isLast: isLast,
          isPending: false,
          nextLabel: l10n.parentHomeworkPlayNext,
          onAdvance: _advanceStep,
        ),
      ),
    );
  }
}
