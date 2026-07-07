import 'package:flutter/material.dart';
import 'package:larnes_mobile/features/auth/models/register_flow.dart';
import 'package:larnes_mobile/features/parent/theme/child_card_colors.dart';
import 'package:larnes_mobile/features/parent/theme/hub_card_appearance.dart';
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

  String description(BuildContext context) {
    final l10n = context.l10n;
    switch (this) {
      case RegisterAccountType.parent:
        return l10n.registerTypeParentHint;
      case RegisterAccountType.teacher:
        return l10n.registerTypeTeacherHint;
      case RegisterAccountType.networkOwner:
        return l10n.registerTypeNetworkOwnerHint;
    }
  }

  ChildCardColorTokens get cardTokens {
    switch (this) {
      case RegisterAccountType.parent:
        return profileHubCardTokens;
      case RegisterAccountType.teacher:
        return childCardColorTokens(ChildCardColor.emerald);
      case RegisterAccountType.networkOwner:
        return childCardColorTokens(ChildCardColor.amber);
    }
  }

  IconData get cardIcon {
    switch (this) {
      case RegisterAccountType.parent:
        return Icons.home_outlined;
      case RegisterAccountType.teacher:
        return Icons.menu_book_outlined;
      case RegisterAccountType.networkOwner:
        return Icons.account_tree_outlined;
    }
  }
}
