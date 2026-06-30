import 'package:flutter/material.dart';
import 'package:larnes_mobile/app/theme/larnes_theme.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/parent/models/parent_homework.dart';
import 'package:larnes_mobile/features/parent/utils/homework_display.dart';
import 'package:larnes_mobile/features/parent/widgets/homework/homework_status_badge.dart';
import 'package:larnes_mobile/features/parent/widgets/parent_scaffold.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

class HomeworkAssignmentCard extends StatelessWidget {
  const HomeworkAssignmentCard({
    super.key,
    required this.assignment,
    required this.onTap,
  });

  final ParentHomeworkAssignment assignment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final localeCode = LocaleScope.of(context).localeCode;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: parentCardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      assignment.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: LarnesColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  HomeworkStatusBadge(displayStatus: assignment.displayStatus),
                ],
              ),
              const SizedBox(height: 12),
              _InfoRow(
                label: l10n.parentHomeworkSentAt,
                value: formatHomeworkDate(assignment.sentAt, localeCode),
              ),
              const SizedBox(height: 6),
              _InfoRow(
                label: l10n.parentHomeworkDeadline,
                value: assignment.deadline == null
                    ? l10n.parentHomeworkNoDeadline
                    : formatHomeworkDeadline(assignment.deadline, localeCode),
              ),
              if (assignment.totalSteps > 0) ...[
                const SizedBox(height: 6),
                _InfoRow(
                  label: l10n.parentHomeworkProgress,
                  value: l10n.parentHomeworkProgressValue(
                    assignment.currentStepIndex,
                    assignment.totalSteps,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: LarnesColors.textSecondary),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 13, color: LarnesColors.textPrimary),
          ),
        ),
      ],
    );
  }
}
