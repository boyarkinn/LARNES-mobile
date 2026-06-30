import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:larnes_mobile/app/theme/larnes_theme.dart';
import 'package:larnes_mobile/core/api/parent_api.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/parent/models/parent_homework.dart';
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
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_loadError != null || _snapshot == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _loadError ?? l10n.parentHomeworkPlayLoadFailed,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _loadSnapshot,
                  child: Text(l10n.continueButton),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final snapshot = _snapshot!;
    final totalSteps = snapshot.steps.length;

    if (totalSteps == 0) {
      return _HomeworkPlayerMessage(
        message: l10n.parentHomeworkPlayEmpty,
        title: snapshot.title,
        actionLabel: l10n.parentHomeworkPlayBackToList,
        onAction: _exit,
      );
    }

    if (_isCompleted || _stepIndex >= totalSteps) {
      return _HomeworkPlayerMessage(
        title: l10n.parentHomeworkPlayCompletedTitle,
        message: snapshot.title,
        actionLabel: l10n.parentHomeworkPlayBackToList,
        onAction: _exit,
      );
    }

    final step = snapshot.steps[_stepIndex];
    final isLast = _stepIndex >= totalSteps - 1;
    final isInteractive = isTrainerInteractive(step.trainerKey);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.parentHomeworkPlayProgress(
                            _stepIndex + 1,
                            totalSteps,
                          ),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.4,
                            color: LarnesColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          snapshot.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: LarnesColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _exit,
                    child: Text(l10n.parentHomeworkPlayExit),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: LarnesColors.border),
            Expanded(
              child: Center(
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
            ),
            const Divider(height: 1, color: LarnesColors.border),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (_advanceError != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        _advanceError!,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  if (isInteractive)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        l10n.parentHomeworkPlayInteractiveHint,
                        style: const TextStyle(
                          fontSize: 14,
                          color: LarnesColors.textSecondary,
                        ),
                      ),
                    )
                  else
                    FilledButton(
                      onPressed: _isAdvancing ? null : _handleAdvance,
                      child: _isAdvancing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              isLast
                                  ? l10n.parentHomeworkPlayFinish
                                  : l10n.parentHomeworkPlayNext,
                            ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeworkPlayerMessage extends StatelessWidget {
  const _HomeworkPlayerMessage({
    required this.actionLabel,
    required this.onAction,
    this.title,
    this.message,
  });

  final String? title;
  final String? message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title != null)
                  Text(
                    title!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: LarnesColors.textPrimary,
                    ),
                  ),
                if (message != null) ...[
                  if (title != null) const SizedBox(height: 8),
                  Text(
                    message!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      color: LarnesColors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                OutlinedButton(
                  onPressed: onAction,
                  child: Text(actionLabel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
