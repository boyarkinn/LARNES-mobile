import 'package:flutter/widgets.dart';
import 'package:larnes_mobile/features/auth/models/register_flow.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';

extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}

extension RegisterAccountTypeL10n on RegisterAccountType {
  String label(BuildContext context) {
    final l10n = context.l10n;
    switch (this) {
      case RegisterAccountType.parent:
        return l10n.accountTypeParent;
      case RegisterAccountType.teacher:
        return l10n.accountTypeTeacher;
      case RegisterAccountType.networkOwner:
        return l10n.accountTypeNetworkOwner;
    }
  }
}
