import 'package:flutter/material.dart';
import 'package:larnes_mobile/app/theme/larnes_theme.dart';
import 'package:larnes_mobile/features/parent/models/parent_program.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

class ProgramProgressBadge extends StatelessWidget {
  const ProgramProgressBadge({
    super.key,
    required this.status,
  });

  final ParentProgramProgressStatus status;

  @override
  Widget build(BuildContext context) {
    if (status == ParentProgramProgressStatus.notStarted) {
      return const SizedBox.shrink();
    }

    final l10n = context.l10n;
    final colors = switch (status) {
      ParentProgramProgressStatus.completed => (
          background: Color(0xFFDCFCE7),
          foreground: Color(0xFF166534),
        ),
      ParentProgramProgressStatus.inProgress => (
          background: Color(0xFFDBEAFE),
          foreground: Color(0xFF1D4ED8),
        ),
      ParentProgramProgressStatus.notStarted => (
          background: Color(0xFFF3F4F6),
          foreground: Color(0xFF374151),
        ),
    };

    final label = switch (status) {
      ParentProgramProgressStatus.completed => l10n.parentProgramStatusCompleted,
      ParentProgramProgressStatus.inProgress => l10n.parentProgramStatusInProgress,
      ParentProgramProgressStatus.notStarted => '',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: colors.foreground,
        ),
      ),
    );
  }
}
