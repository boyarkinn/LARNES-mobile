import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:larnes_mobile/app/theme/admin_theme.dart';
import 'package:larnes_mobile/features/admin/models/trainer_workflow.dart';
import 'package:larnes_mobile/features/admin/widgets/trainer_dev_feed_panel.dart';
import 'package:larnes_mobile/features/admin/widgets/trainer_signoff_panel.dart';
import 'package:larnes_mobile/features/admin/widgets/trainer_workflow_funnel.dart';
import 'package:larnes_mobile/features/admin/widgets/trainer_workflow_section.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';

class TrainerWorkflowPanel extends StatefulWidget {
  const TrainerWorkflowPanel({
    super.key,
    required this.detail,
    required this.l10n,
    required this.onSignoff,
    required this.onCreateComment,
    required this.onUpdateCommentStatus,
    this.pendingSignoff,
    this.pendingCommentId,
    this.pendingCommentStatus,
    this.isSubmittingComment = false,
    this.isMutating = false,
    this.mutationError,
  });

  final TrainerWorkflowDetail detail;
  final AppLocalizations l10n;
  final Future<void> Function(TrainerWorkflowPlatform platform, TrainerSignoffStatus status) onSignoff;
  final Future<void> Function(TrainerWorkflowPlatform platform, String body) onCreateComment;
  final Future<void> Function(String commentId, TrainerDevCommentStatus status) onUpdateCommentStatus;
  final TrainerSignoffStatus? pendingSignoff;
  final String? pendingCommentId;
  final TrainerDevCommentStatus? pendingCommentStatus;
  final bool isSubmittingComment;
  final bool isMutating;
  final String? mutationError;

  @override
  State<TrainerWorkflowPanel> createState() => _TrainerWorkflowPanelState();
}

class _TrainerWorkflowPanelState extends State<TrainerWorkflowPanel> {
  TrainerWorkflowPlatform _activePlatform = TrainerWorkflowPlatform.mobile;

  TrainerWorkflowSnapshot get _snapshot => widget.detail.snapshotFor(_activePlatform);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        SegmentedButton<TrainerWorkflowPlatform>(
          segments: [
            ButtonSegment(
              value: TrainerWorkflowPlatform.web,
              label: Text(widget.l10n.adminTrainersPlatformWeb),
            ),
            ButtonSegment(
              value: TrainerWorkflowPlatform.mobile,
              label: Text(widget.l10n.adminTrainersPlatformMobile),
            ),
          ],
          selected: {_activePlatform},
          onSelectionChanged: widget.isMutating
              ? null
              : (selection) {
                  setState(() {
                    _activePlatform = selection.first;
                  });
                },
          style: ButtonStyle(
            visualDensity: VisualDensity.compact,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(height: 16),
        TrainerWorkflowSection(
          title: widget.l10n.adminTrainerWorkflowSectionFunnel,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TrainerWorkflowFunnel(
                status: _snapshot.release.lifecycleStatus,
                l10n: widget.l10n,
              ),
              if (_snapshot.inProgressCommentCount > 0) ...[
                const SizedBox(height: 8),
                Text(
                  widget.l10n.adminTrainerWorkflowInProgressCount(_snapshot.inProgressCommentCount),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFFB45309),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        TrainerWorkflowSection(
          title: widget.l10n.adminTrainerWorkflowSectionTeam,
          child: TrainerSignoffPanel(
            snapshot: _snapshot,
            currentUserId: widget.detail.currentUserId,
            l10n: widget.l10n,
            onSignoff: (status) => widget.onSignoff(_activePlatform, status),
            pendingSignoff: widget.pendingSignoff,
            isDisabled: widget.isMutating,
          ),
        ),
        const SizedBox(height: 16),
        TrainerWorkflowSection(
          title: widget.l10n.adminTrainerWorkflowSectionFeed,
          child: TrainerDevFeedPanel(
            snapshot: _snapshot,
            l10n: widget.l10n,
            onCreateComment: (body) => widget.onCreateComment(_activePlatform, body),
            onUpdateCommentStatus: widget.onUpdateCommentStatus,
            pendingCommentId: widget.pendingCommentId,
            pendingStatus: widget.pendingCommentStatus,
            isSubmittingComment: widget.isSubmittingComment,
            isDisabled: widget.isMutating,
            errorMessage: widget.mutationError,
          ),
        ),
      ],
    );
  }
}
