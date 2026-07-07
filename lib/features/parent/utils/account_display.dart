import 'package:larnes_mobile/core/formatting/date_of_birth_input.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';

String formatAccountDateOfBirth(String? isoDate, String localeCode) {
  return isoDateToDisplay(isoDate);
}

String formatChildrenCount(AppLocalizations l10n, int count) {
  return l10n.parentAccountChildrenCount(count);
}
