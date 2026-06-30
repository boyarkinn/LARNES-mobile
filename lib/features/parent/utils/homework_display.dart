import 'package:intl/intl.dart';
import 'package:larnes_mobile/features/parent/models/parent_homework.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';

String formatHomeworkDate(DateTime date, String localeCode) {
  return DateFormat.yMd(localeCode).format(date.toLocal());
}

String formatHomeworkDeadline(String? isoDate, String localeCode) {
  if (isoDate == null || isoDate.isEmpty) {
    return '';
  }
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
    case ParentHomeworkTab.overdue:
      return l10n.parentHomeworkTabOverdue(count);
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
    case ParentHomeworkTab.overdue:
      return l10n.parentHomeworkEmptyOverdue;
    case ParentHomeworkTab.upcoming:
      return l10n.parentHomeworkEmptyUpcoming;
  }
}

String homeworkStatusLabel(AppLocalizations l10n, String displayStatus) {
  switch (displayStatus) {
    case 'assigned':
      return l10n.parentHomeworkStatusAssigned;
    case 'in_progress':
      return l10n.parentHomeworkStatusInProgress;
    case 'completed':
      return l10n.parentHomeworkStatusCompleted;
    case 'overdue':
      return l10n.parentHomeworkStatusOverdue;
    default:
      return displayStatus;
  }
}
