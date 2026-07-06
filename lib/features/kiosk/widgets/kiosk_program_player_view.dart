import 'package:flutter/material.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';
import 'package:larnes_mobile/core/api/kiosk_program_api.dart';
import 'package:larnes_mobile/features/parent/models/parent_program.dart';
import 'package:larnes_mobile/features/parent/utils/program_player_lesson_bounds.dart';
import 'package:larnes_mobile/features/parent/widgets/parent_player_shell.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';
import 'package:larnes_mobile/trainers/runtime/trainer_player.dart';

class KioskProgramPlayerView extends StatefulWidget {
  const KioskProgramPlayerView({
    super.key,
    required this.programId,
    required this.programApi,
    this.childDisplayName,
    this.onExit,
    this.locale = 'ru',
  });

  final String programId;
  final KioskProgramGateway programApi;
  final String? childDisplayName;
  final VoidCallback? onExit;
  final String locale;

  @override
  State<KioskProgramPlayerView> createState() => _KioskProgramPlayerViewState();
}

class _KioskProgramPlayerViewState extends State<KioskProgramPlayerView> {
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
      final snapshot = await widget.programApi.fetchPlaySnapshot(
        widget.programId,
        locale: widget.locale,
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
    } on KioskProgramApiException catch (error) {
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
      final result = await widget.programApi.completeLesson(
        programId: widget.programId,
        topicOrdinal: step.topicOrdinal,
        lessonOrdinal: step.lessonOrdinal,
        locale: widget.locale,
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
    } on KioskProgramApiException catch (error) {
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

  void _handleExit() {
    widget.onExit?.call();
  }

  String _eyebrow(AppLocalizations l10n, ProgramPlayerLessonBounds lessonBounds) {
    final childName = widget.childDisplayName?.trim();
    if (childName != null && childName.isNotEmpty) {
      return childName.toUpperCase();
    }

    return l10n
        .parentProgramPlayLessonProgress(
          lessonBounds.topicOrdinal,
          lessonBounds.lessonOrdinal,
          lessonBounds.currentInLesson,
          lessonBounds.totalInLesson,
        )
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return _buildContent(context.l10n);
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
        onAction: _handleExit,
      );
    }

    if (_isCompleted || _stepIndex >= snapshot.steps.length) {
      return ParentPlayerState(
        title: l10n.parentProgramPlayCompletedTitle,
        message: snapshot.title,
        actionLabel: l10n.parentProgramPlayBackToHub,
        onAction: _handleExit,
      );
    }

    final step = snapshot.steps[_stepIndex];
    final lessonBounds = computeProgramPlayerLessonBounds(snapshot.steps, _stepIndex);
    final isInteractive = isTrainerInteractive(step.trainerKey);

    return ParentPlayerShell(
      eyebrow: _eyebrow(l10n, lessonBounds),
      title: snapshot.title,
      exitLabel: l10n.parentProgramPlayExit,
      onExit: _handleExit,
      showExitButton: false,
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
