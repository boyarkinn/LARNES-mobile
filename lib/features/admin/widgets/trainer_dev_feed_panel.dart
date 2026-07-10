import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:larnes_mobile/app/theme/admin_theme.dart';
import 'package:larnes_mobile/features/admin/models/trainer_workflow.dart';
import 'package:larnes_mobile/features/admin/widgets/trainer_workflow_section.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';

class TrainerDevFeedPanel extends StatefulWidget {
  const TrainerDevFeedPanel({
    super.key,
    required this.snapshot,
    required this.l10n,
    required this.onCreateComment,
    required this.onUpdateCommentStatus,
    this.pendingCommentId,
    this.pendingStatus,
    this.isSubmittingComment = false,
    this.isDisabled = false,
    this.errorMessage,
  });

  final TrainerWorkflowSnapshot snapshot;
  final AppLocalizations l10n;
  final Future<void> Function(String body) onCreateComment;
  final Future<void> Function(String commentId, TrainerDevCommentStatus status) onUpdateCommentStatus;
  final String? pendingCommentId;
  final TrainerDevCommentStatus? pendingStatus;
  final bool isSubmittingComment;
  final bool isDisabled;
  final String? errorMessage;

  @override
  State<TrainerDevFeedPanel> createState() => _TrainerDevFeedPanelState();
}

class _TrainerDevFeedPanelState extends State<TrainerDevFeedPanel> {
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final body = _commentController.text.trim();

    if (body.isEmpty) {
      return;
    }

    await widget.onCreateComment(body);

    if (mounted) {
      _commentController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd.MM HH:mm');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.snapshot.feed.isEmpty)
          Text(
            widget.l10n.adminTrainerWorkflowFeedEmpty,
            style: GoogleFonts.inter(fontSize: 14, color: AdminColors.inkMuted),
          )
        else
          Column(
            children: [
              for (var index = 0; index < widget.snapshot.feed.length; index++) ...[
                if (index > 0) const SizedBox(height: 8),
                _FeedItemCard(
                  item: widget.snapshot.feed[index],
                  l10n: widget.l10n,
                  dateFormat: dateFormat,
                  onUpdateStatus: widget.onUpdateCommentStatus,
                  pendingCommentId: widget.pendingCommentId,
                  pendingStatus: widget.pendingStatus,
                  isDisabled: widget.isDisabled,
                ),
              ],
            ],
          ),
        const SizedBox(height: 12),
        TrainerWorkflowSection(
          title: widget.l10n.adminTrainerWorkflowCommentAddTitle,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _commentController,
                minLines: 3,
                maxLines: 5,
                enabled: !widget.isDisabled && !widget.isSubmittingComment,
                decoration: InputDecoration(
                  hintText: widget.l10n.adminTrainerWorkflowCommentBodyPlaceholder,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: AdminColors.accent),
                  onPressed: widget.isDisabled || widget.isSubmittingComment ? null : _submitComment,
                  child: widget.isSubmittingComment
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(widget.l10n.adminTrainerWorkflowCommentAddSubmit),
                ),
              ),
              if (widget.errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  widget.errorMessage!,
                  style: const TextStyle(fontSize: 11, color: Color(0xFFDC2626)),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _FeedItemCard extends StatelessWidget {
  const _FeedItemCard({
    required this.item,
    required this.l10n,
    required this.dateFormat,
    required this.onUpdateStatus,
    required this.pendingCommentId,
    required this.pendingStatus,
    required this.isDisabled,
  });

  final TrainerDevFeedItem item;
  final AppLocalizations l10n;
  final DateFormat dateFormat;
  final Future<void> Function(String commentId, TrainerDevCommentStatus status) onUpdateStatus;
  final String? pendingCommentId;
  final TrainerDevCommentStatus? pendingStatus;
  final bool isDisabled;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AdminColors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${dateFormat.format(item.createdAt)} · ${item.authorName}',
                    style: GoogleFonts.inter(fontSize: 11, color: AdminColors.inkMuted),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Text(
                      _statusLabel(l10n, item.status),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AdminColors.ink,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              item.body,
              style: GoogleFonts.inter(fontSize: 14, color: AdminColors.ink),
            ),
            if (item.attachments.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final attachment in item.attachments)
                    TrainerWorkflowAttachmentImage(dataUrl: attachment.dataUrl),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                for (final status in TrainerDevCommentStatus.values)
                  _CommentStatusButton(
                    label: _actionLabel(l10n, status),
                    status: status,
                    selected: item.status == status,
                    isPending: pendingCommentId == item.id && pendingStatus == status,
                    isDisabled: isDisabled,
                    onPressed: () => onUpdateStatus(item.id, status),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(AppLocalizations l10n, TrainerDevCommentStatus status) {
    switch (status) {
      case TrainerDevCommentStatus.inProgress:
        return l10n.adminTrainerWorkflowCommentStatusInProgress;
      case TrainerDevCommentStatus.implemented:
        return l10n.adminTrainerWorkflowCommentStatusImplemented;
      case TrainerDevCommentStatus.rejected:
        return l10n.adminTrainerWorkflowCommentStatusRejected;
    }
  }

  String _actionLabel(AppLocalizations l10n, TrainerDevCommentStatus status) {
    switch (status) {
      case TrainerDevCommentStatus.inProgress:
        return l10n.adminTrainerWorkflowCommentActionInProgress;
      case TrainerDevCommentStatus.implemented:
        return l10n.adminTrainerWorkflowCommentActionImplemented;
      case TrainerDevCommentStatus.rejected:
        return l10n.adminTrainerWorkflowCommentActionRejected;
    }
  }
}

class _CommentStatusButton extends StatelessWidget {
  const _CommentStatusButton({
    required this.label,
    required this.status,
    required this.selected,
    required this.isPending,
    required this.isDisabled,
    required this.onPressed,
  });

  final String label;
  final TrainerDevCommentStatus status;
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : Text(label, style: const TextStyle(fontSize: 10)),
    );
  }
}
