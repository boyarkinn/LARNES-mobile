import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';
import 'package:larnes_mobile/core/api/parent_api.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/parent/models/parent_homework.dart';
import 'package:larnes_mobile/features/parent/widgets/parent_player_shell.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';
import 'package:larnes_mobile/trainers/runtime/trainer_player.dart';

class HomeworkPlayerScreen extends StatefulWidget {
  const HomeworkPlayerScreen({
    super.key,
    required this.childId,
    required this.assignmentId,
  });

  final String childId;
  final String assignmentId;

  @override
  State<HomeworkPlayerScreen> createState() => _HomeworkPlayerScreenState();
}

class _HomeworkPlayerScreenState extends State<HomeworkPlayerScreen> {
  bool _isLoading = true;
  String? _loadError;
  ParentHomeworkPlaySnapshot? _snapshot;
  int _stepIndex = 0;
  bool _isCompleted = false;
  bool _isAdvancing = false;
  String? _advanceError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadSnapshot();
      }
    });
  }

  Future<void> _loadSnapshot() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final locale = LocaleScope.read(context).localeCode;
      final snapshot = await AuthScope.of(context).parentApi.fetchHomeworkSnapshot(
        widget.childId,
        widget.assignmentId,
        locale: locale,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _snapshot = snapshot;
        _stepIndex = snapshot.currentStepIndex;
        _isCompleted = snapshot.isCompleted;
        _isLoading = false;
      });
    } on ParentApiException catch (error) {
      if (mounted) {
        setState(() {
          _loadError = error.message;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadError = context.l10n.parentHomeworkPlayLoadFailed;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleAdvance() async {
    final snapshot = _snapshot;
    if (snapshot == null || _isAdvancing) {
      return;
    }

    final totalSteps = snapshot.steps.length;
    final nextStepIndex = _stepIndex + 1;

    setState(() {
      _advanceError = null;
      _isAdvancing = true;
    });

    try {
      final locale = LocaleScope.read(context).localeCode;
      await AuthScope.of(context).parentApi.advanceHomeworkStep(
        childId: widget.childId,
        assignmentId: widget.assignmentId,
        nextStepIndex: nextStepIndex,
        totalSteps: totalSteps,
        locale: locale,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isAdvancing = false;
        if (nextStepIndex >= totalSteps) {
          _isCompleted = true;
        } else {
          _stepIndex = nextStepIndex;
        }
      });
    } on ParentApiException catch (error) {
      if (mounted) {
        setState(() {
          _advanceError = error.message;
          _isAdvancing = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _advanceError = context.l10n.parentHomeworkPlayAdvanceFailed;
          _isAdvancing = false;
        });
      }
    }
  }

  void _exit() {
    final completed = _isCompleted || (_snapshot?.isCompleted ?? false);
    context.pop(completed);
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
        _exit();
      },
      child: _buildContent(l10n),
    );
  }

  Widget _buildContent(AppLocalizations l10n) {
    if (_isLoading) {
      return const ParentPlayerLoading();
    }

    if (_loadError != null || _snapshot == null) {
      return ParentPlayerError(
        message: _loadError ?? l10n.parentHomeworkPlayLoadFailed,
        retryLabel: l10n.continueButton,
        onRetry: _loadSnapshot,
      );
    }

    final snapshot = _snapshot!;
    final totalSteps = snapshot.steps.length;

    if (totalSteps == 0) {
      return ParentPlayerState(
        message: l10n.parentHomeworkPlayEmpty,
        title: snapshot.title,
        actionLabel: l10n.parentHomeworkPlayBackToList,
        onAction: _exit,
      );
    }

    if (_isCompleted || _stepIndex >= totalSteps) {
      return ParentPlayerState(
        title: l10n.parentHomeworkPlayCompletedTitle,
        message: snapshot.title,
        actionLabel: l10n.parentHomeworkPlayBackToList,
        onAction: _exit,
      );
    }

    final step = snapshot.steps[_stepIndex];
    final isLast = _stepIndex >= totalSteps - 1;
    final isInteractive = isTrainerInteractive(step.trainerKey);

    return ParentPlayerShell(
      eyebrow: l10n.parentHomeworkPlayProgress(_stepIndex + 1, totalSteps).toUpperCase(),
      title: snapshot.title,
      exitLabel: l10n.parentHomeworkPlayExit,
      onExit: _exit,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: TrainerPlayer(
            key: ValueKey(step.id),
            trainerKey: step.trainerKey,
            params: step.params,
            l10n: l10n,
            onComplete: isInteractive ? _handleAdvance : null,
          ),
        ),
      ),
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (_advanceError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _advanceError!,
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 13, color: Color(0xFFDC2626)),
              ),
            ),
          if (isInteractive)
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                l10n.parentHomeworkPlayInteractiveHint,
                style: const TextStyle(fontSize: 14, color: ParentColors.inkMuted),
              ),
            )
          else
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: ParentColors.shell),
                onPressed: _isAdvancing ? null : _handleAdvance,
                child: _isAdvancing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(isLast ? l10n.parentHomeworkPlayFinish : l10n.parentHomeworkPlayNext),
              ),
            ),
        ],
      ),
    );
  }
}
