import 'package:flutter/material.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/parent/models/parent_homework.dart';
import 'package:larnes_mobile/features/parent/theme/hub_card_appearance.dart';
import 'package:larnes_mobile/features/parent/utils/homework_display.dart';
import 'package:larnes_mobile/features/parent/widgets/study_hub_card.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

/// Карточка задания на списке ДЗ (StudyHubCard + status band).
/// Эталон: platform parent-homework-list.tsx
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

    return StudyHubCard(
      title: assignment.title,
      subtitle: buildHomeworkCardSubtitle(l10n, assignment, localeCode),
      tokens: homeworkAssignmentCardTokens(assignment.displayStatus),
      icon: HubCardIconKind.homework,
      onTap: onTap,
    );
  }
}
