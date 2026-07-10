import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:larnes_mobile/app/theme/admin_theme.dart';
import 'package:larnes_mobile/features/admin/models/trainer_workflow.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';

class TrainerSignoffPanel extends StatelessWidget {
  const TrainerSignoffPanel({
    super.key,
    required this.snapshot,
    required this.currentUserId,
    required this.l10n,
    required this.onSignoff,
    this.pendingSignoff,
    this.isDisabled = false,
  });

  final TrainerWorkflowSnapshot snapshot;
  final String currentUserId;
  final AppLocalizations l10n;
  final ValueChanged<TrainerSignoffStatus> onSignoff;
  final TrainerSignoffStatus? pendingSignoff;
  final bool isDisabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < snapshot.reviewers.length; index++) ...[
          if (index > 0) const SizedBox(height: 8),
          _ReviewerRow(
            reviewer: snapshot.reviewers[index],
            currentUserId: currentUserId,
            l10n: l10n,
            onSignoff: onSignoff,
            pendingSignoff: pendingSignoff,
            isDisabled: isDisabled,
          ),
        ],
      ],
    );
  }
}

class _ReviewerRow extends StatelessWidget {
  const _ReviewerRow({
    required this.reviewer,
    required this.currentUserId,
    required this.l10n,
    required this.onSignoff,
    required this.pendingSignoff,
    required this.isDisabled,
  });

  final TrainerWorkflowReviewer reviewer;
  final String currentUserId;
  final AppLocalizations l10n;
  final ValueChanged<TrainerSignoffStatus> onSignoff;
  final TrainerSignoffStatus? pendingSignoff;
  final bool isDisabled;

  @override
  Widget build(BuildContext context) {
    final isSelf = reviewer.userId == currentUserId;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AdminColors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reviewer.displayName,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AdminColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _statusLabel(l10n, reviewer.signoffStatus),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _statusColor(reviewer.signoffStatus),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelf) ...[
              const SizedBox(width: 8),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  _SignoffButton(
                    label: l10n.adminTrainerWorkflowSignoffActionNeedsFixes,
                    status: TrainerSignoffStatus.needsFixes,
                    selected: reviewer.signoffStatus == TrainerSignoffStatus.needsFixes,
                    isPending: pendingSignoff == TrainerSignoffStatus.needsFixes,
                    isDisabled: isDisabled,
                    onPressed: () => onSignoff(TrainerSignoffStatus.needsFixes),
                  ),
                  _SignoffButton(
                    label: l10n.adminTrainerWorkflowSignoffActionReadyForRelease,
                    status: TrainerSignoffStatus.readyForRelease,
                    selected: reviewer.signoffStatus == TrainerSignoffStatus.readyForRelease,
                    isPending: pendingSignoff == TrainerSignoffStatus.readyForRelease,
                    isDisabled: isDisabled,
                    onPressed: () => onSignoff(TrainerSignoffStatus.readyForRelease),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _statusLabel(AppLocalizations l10n, TrainerSignoffStatus? status) {
    switch (status) {
      case TrainerSignoffStatus.needsFixes:
        return l10n.adminTrainerWorkflowSignoffStatusNeedsFixes;
      case TrainerSignoffStatus.readyForRelease:
        return l10n.adminTrainerWorkflowSignoffStatusReadyForRelease;
      case null:
        return l10n.adminTrainerWorkflowSignoffStatusUnset;
    }
  }

  Color _statusColor(TrainerSignoffStatus? status) {
    switch (status) {
      case TrainerSignoffStatus.needsFixes:
        return const Color(0xFFB45309);
      case TrainerSignoffStatus.readyForRelease:
        return const Color(0xFF047857);
      case null:
        return AdminColors.inkMuted;
    }
  }
}

class _SignoffButton extends StatelessWidget {
  const _SignoffButton({
    required this.label,
    required this.status,
    required this.selected,
    required this.isPending,
    required this.isDisabled,
    required this.onPressed,
  });

  final String label;
  final TrainerSignoffStatus status;
  final bool selected;
  final bool isPending;
  final bool isDisabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: selected ? AdminColors.accent : AdminColors.surface,
        foregroundColor: selected ? Colors.white : AdminColors.ink,
        disabledBackgroundColor: AdminColors.line,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: selected ? AdminColors.accent : AdminColors.line),
        ),
      ),
      onPressed: isDisabled || isPending ? null : onPressed,
      child: isPending
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : Text(label, style: const TextStyle(fontSize: 11)),
    );
  }
}
