import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';
import 'package:larnes_mobile/core/api/parent_api.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/parent/models/parent_program.dart';
import 'package:larnes_mobile/features/parent/widgets/parent_player_shell.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';
import 'package:larnes_mobile/trainers/runtime/trainer_player.dart';

class ProgramPlayerScreen extends StatefulWidget {
  const ProgramPlayerScreen({
    super.key,
    required this.childId,
    required this.programId,
  });

  final String childId;
  final String programId;

  @override
  State<ProgramPlayerScreen> createState() => _ProgramPlayerScreenState();
}

class _ProgramPlayerScreenState extends State<ProgramPlayerScreen> {
  bool _isLoading = true;
  String? _loadError;
  ParentProgramPlaySnapshot? _snapshot;
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
      final snapshot = await AuthScope.of(context).parentApi.fetchProgramSnapshot(
        widget.childId,
        widget.programId,
        locale: locale,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _snapshot = snapshot;
        _stepIndex = 0;
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
          _loadError = context.l10n.parentProgramPlayLoadFailed;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleAdvance() async {
    final snapshot = _snapshot;
    final step = snapshot?.steps.elementAtOrNull(_stepIndex);
    if (snapshot == null || step == null || _isAdvancing) {
      return;
    }

    setState(() {
      _advanceError = null;
    });

    if (!step.isLastInLesson) {
      setState(() {
        _stepIndex += 1;
      });
      return;
    }

    setState(() {
      _isAdvancing = true;
    });

    try {
      final locale = LocaleScope.read(context).localeCode;
      final result = await AuthScope.of(context).parentApi.completeProgramLesson(
        childId: widget.childId,
        programId: widget.programId,
        topicOrdinal: step.topicOrdinal,
        lessonOrdinal: step.lessonOrdinal,
        locale: locale,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isAdvancing = false;
        if (result.isProgramCompleted || step.isLastInProgram) {
          _isCompleted = true;
        } else {
          _stepIndex += 1;
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
          _advanceError = context.l10n.parentProgramPlayCompleteFailed;
          _isAdvancing = false;
        });
      }
    }
  }

  void _exit() {
    context.pop(_isCompleted || (_snapshot?.isCompleted ?? false));
  }

  _LessonStepBounds _lessonBounds(List<ParentProgramPlayStep> steps, int stepIndex) {
    final currentStep = steps.elementAtOrNull(stepIndex);
    if (currentStep == null) {
      return const _LessonStepBounds(
        currentInLesson: 0,
        lessonOrdinal: 0,
        topicOrdinal: 0,
        totalInLesson: 0,
      );
    }

    var lessonStart = stepIndex;
    while (lessonStart > 0) {
      final previous = steps[lessonStart - 1];
      if (previous.topicOrdinal != currentStep.topicOrdinal ||
          previous.lessonOrdinal != currentStep.lessonOrdinal) {
        break;
      }
      lessonStart -= 1;
    }

    var lessonEnd = stepIndex;
    while (lessonEnd < steps.length - 1 && !steps[lessonEnd].isLastInLesson) {
      lessonEnd += 1;
    }

    return _LessonStepBounds(
      currentInLesson: stepIndex - lessonStart + 1,
      lessonOrdinal: currentStep.lessonOrdinal,
      topicOrdinal: currentStep.topicOrdinal,
      totalInLesson: lessonEnd - lessonStart + 1,
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
        message: _loadError ?? l10n.parentProgramPlayLoadFailed,
        retryLabel: l10n.continueButton,
        onRetry: _loadSnapshot,
      );
    }

    final snapshot = _snapshot!;

    if (snapshot.steps.isEmpty && !_isCompleted) {
      final message = snapshot.unavailableReason == ParentProgramUnavailableReason.emptyLesson
          ? l10n.parentProgramPlayEmptyLesson(
              snapshot.topicOrdinal,
              snapshot.lessonOrdinal,
            )
          : l10n.parentProgramPlayEmptyProgram;

      return ParentPlayerState(
        message: message,
        actionLabel: l10n.parentProgramPlayBackToHub,
        onAction: _exit,
      );
    }

    if (_isCompleted || _stepIndex >= snapshot.steps.length) {
      return ParentPlayerState(
        title: l10n.parentProgramPlayCompletedTitle,
        message: snapshot.title,
        actionLabel: l10n.parentProgramPlayBackToHub,
        onAction: _exit,
      );
    }

    final step = snapshot.steps[_stepIndex];
    final lessonBounds = _lessonBounds(snapshot.steps, _stepIndex);
    final isInteractive = isTrainerInteractive(step.trainerKey);

    return ParentPlayerShell(
      eyebrow: l10n
          .parentProgramPlayLessonProgress(
            lessonBounds.topicOrdinal,
            lessonBounds.lessonOrdinal,
            lessonBounds.currentInLesson,
            lessonBounds.totalInLesson,
          )
          .toUpperCase(),
      title: snapshot.title,
      exitLabel: l10n.parentProgramPlayExit,
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
                l10n.parentProgramPlayInteractiveHint,
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
                    : Text(
                        step.isLastInProgram
                            ? l10n.parentProgramPlayFinish
                            : l10n.parentProgramPlayNext,
                      ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LessonStepBounds {
  const _LessonStepBounds({
    required this.currentInLesson,
    required this.lessonOrdinal,
    required this.topicOrdinal,
    required this.totalInLesson,
  });

  final int currentInLesson;
  final int lessonOrdinal;
  final int topicOrdinal;
  final int totalInLesson;
}
