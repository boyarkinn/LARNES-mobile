import 'package:intl/intl.dart';
import 'package:larnes_mobile/features/parent/models/parent_homework.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';

String formatHomeworkDate(DateTime date, String localeCode) {
  return DateFormat.yMd(localeCode).format(date.toLocal());
}

String formatHomeworkAvailableOn(String isoDate, String localeCode) {
  final date = DateTime.tryParse('${isoDate}T00:00:00');
  if (date == null) {
    return isoDate;
  }
  return DateFormat.yMd(localeCode).format(date);
}

String homeworkTabLabel(AppLocalizations l10n, ParentHomeworkTab tab, int count) {
  switch (tab) {
    case ParentHomeworkTab.due:
      return l10n.parentHomeworkTabDue(count);
    case ParentHomeworkTab.completed:
      return l10n.parentHomeworkTabCompleted(count);
    case ParentHomeworkTab.upcoming:
      return l10n.parentHomeworkTabUpcoming(count);
  }
}

String homeworkEmptyMessage(AppLocalizations l10n, ParentHomeworkTab tab) {
  switch (tab) {
    case ParentHomeworkTab.due:
      return l10n.parentHomeworkEmptyDue;
    case ParentHomeworkTab.completed:
      return l10n.parentHomeworkEmptyCompleted;
    case ParentHomeworkTab.upcoming:
      return l10n.parentHomeworkEmptyUpcoming;
  }
}

String buildHomeworkCardSubtitle(
  AppLocalizations l10n,
  ParentHomeworkAssignment assignment,
  String localeCode,
) {
  final statusLabel = homeworkStatusLabel(l10n, assignment.displayStatus);
  final availableOn = formatHomeworkAvailableOn(
    assignment.availableOn,
    localeCode,
  );
  final parts = <String>[
    '$statusLabel · ${l10n.parentHomeworkAvailableOn}: $availableOn',
  ];

  if (assignment.totalSteps > 0) {
    parts.add(
      l10n.parentHomeworkProgressValue(
        assignment.currentStepIndex,
        assignment.totalSteps,
      ),
    );
  }

  return parts.join(' · ');
}

String homeworkStatusLabel(AppLocalizations l10n, String displayStatus) {
  switch (displayStatus) {
    case 'assigned':
      return l10n.parentHomeworkStatusAssigned;
    case 'in_progress':
      return l10n.parentHomeworkStatusInProgress;
    case 'completed':
      return l10n.parentHomeworkStatusCompleted;
    case 'missed':
      return l10n.parentHomeworkStatusMissed;
    case 'cancelled':
      return l10n.parentHomeworkStatusCancelled;
    case 'upcoming':
      return l10n.parentHomeworkStatusUpcoming;
    default:
      return displayStatus;
  }
}
