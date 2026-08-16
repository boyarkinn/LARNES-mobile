import 'dart:async';

import 'package:flutter/material.dart';
import 'package:larnes_mobile/core/api/kiosk_trainer_api.dart';
import 'package:larnes_mobile/features/parent/models/parent_homework.dart';
import 'package:larnes_mobile/features/parent/widgets/parent_player_shell.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';
import 'package:larnes_mobile/trainers/runtime/trainer_play_shell.dart';
import 'package:larnes_mobile/trainers/runtime/trainer_player.dart';
import 'package:larnes_mobile/trainers/runtime/trainer_step_chrome.dart';

class KioskTrainerPlayerView extends StatefulWidget {
  const KioskTrainerPlayerView({
    super.key,
    required this.trainerApi,
    required this.reloadToken,
    this.onExit,
    this.locale = 'ru',
  });

  final KioskTrainerApi trainerApi;
  final int reloadToken;
  final VoidCallback? onExit;
  final String locale;

  @override
  State<KioskTrainerPlayerView> createState() => _KioskTrainerPlayerViewState();
}

class _KioskTrainerPlayerViewState extends State<KioskTrainerPlayerView> {
  bool _isLoading = true;
  bool _isProcessing = false;
  String? _loadError;
  ParentHomeworkPlaySnapshot? _snapshot;
  int _stepIndex = 0;
  Timer? _retryTimer;
  int _retryAttempts = 0;

  static const _maxRetryAttempts = 20;
  static const _retryInterval = Duration(milliseconds: 1000);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadSnapshot();
      }
    });
  }

  @override
  void didUpdateWidget(covariant KioskTrainerPlayerView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reloadToken != widget.reloadToken) {
      _retryAttempts = 0;
      _loadSnapshot();
    }
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();
    if (_retryAttempts >= _maxRetryAttempts) {
      return;
    }

    _retryTimer = Timer(_retryInterval, () {
      if (mounted) {
        _loadSnapshot();
      }
    });
  }

  Future<void> _loadSnapshot() async {
    _retryTimer?.cancel();
    setState(() {
      _isLoading = _snapshot == null;
      _isProcessing = _snapshot == null;
      _loadError = null;
    });

    try {
      final snapshot = await widget.trainerApi.fetchPlaySnapshot(
        locale: widget.locale,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _snapshot = snapshot;
        _stepIndex = snapshot.currentStepIndex;
        _isLoading = false;
        _isProcessing = false;
        _retryAttempts = 0;
      });

      if (snapshot.isCompleted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _exit();
          }
        });
      }
    } on KioskTrainerApiException catch (error) {
      if (!mounted) {
        return;
      }

      final shouldRetry = error.statusCode == 404 && _retryAttempts < _maxRetryAttempts;
      _retryAttempts += 1;

      setState(() {
        _isLoading = false;
        _isProcessing = shouldRetry;
        _loadError = shouldRetry ? null : error.message;
      });

      if (shouldRetry) {
        _scheduleRetry();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadError = context.l10n.requestFailed;
          _isLoading = false;
          _isProcessing = false;
        });
      }
    }
  }

  void _handleAdvance() {
    final snapshot = _snapshot;
    if (snapshot == null) {
      return;
    }

    final totalSteps = snapshot.steps.length;
    final nextStepIndex = _stepIndex + 1;

    if (nextStepIndex >= totalSteps) {
      _exit();
      return;
    }

    setState(() => _stepIndex = nextStepIndex);
  }

  void _exit() {
    widget.onExit?.call();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (_isLoading || _isProcessing) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null || _snapshot == null) {
      return ParentPlayerError(
        message: _loadError ?? l10n.requestFailed,
        retryLabel: l10n.continueButton,
        onRetry: _loadSnapshot,
      );
    }

    final snapshot = _snapshot!;
    final totalSteps = snapshot.steps.length;

    if (totalSteps == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _exit();
        }
      });
      return const SizedBox.shrink();
    }

    final step = snapshot.steps[_stepIndex];
    final isLast = _stepIndex >= totalSteps - 1;
    final isInteractive = isTrainerInteractive(step.trainerKey);

    return TrainerPlayShell(
      currentStep: _stepIndex + 1,
      totalSteps: totalSteps,
      menuContinueLabel: l10n.parentHomeworkPlayMenuContinue,
      menuExitLabel: l10n.kioskTrainerCompletedBack,
      edgeToEdge: true,
      onExit: _exit,
      child: TrainerPlayer(
        key: ValueKey('${snapshot.assignmentId}-${widget.reloadToken}-${step.id}'),
        trainerKey: step.trainerKey,
        params: step.params,
        l10n: l10n,
        onComplete: isInteractive ? _handleAdvance : null,
        stepChrome: TrainerStepChrome(
          finishLabel: l10n.parentHomeworkPlayFinish,
          isInteractive: isInteractive,
          isLast: isLast,
          isPending: false,
          nextLabel: l10n.parentHomeworkPlayNext,
          onAdvance: _handleAdvance,
        ),
      ),
    );
  }
}
