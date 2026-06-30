import 'package:larnes_mobile/l10n/app_localizations.dart';

String formatAccountDateOfBirth(String? isoDate, String localeCode) {
  if (isoDate == null || isoDate.isEmpty) {
    return '';
  }
  final date = DateTime.tryParse('${isoDate}T00:00:00');
  if (date == null) {
    return isoDate;
  }
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day.$month.${date.year}';
}

String formatChildrenCount(AppLocalizations l10n, int count) {
  return l10n.parentAccountChildrenCount(count);
}
