import 'package:flutter/material.dart';
import 'package:larnes_mobile/features/auth/models/register_flow.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

List<String> registerWizardStepLabels(BuildContext context) {
  final l10n = context.l10n;
  return [
    l10n.registerWizardStepContact,
    l10n.registerWizardStepOtp,
    l10n.registerWizardStepProfile,
  ];
}

List<String> passwordResetStepLabels(BuildContext context) {
  final l10n = context.l10n;
  return [
    l10n.passwordResetWizardStepContact,
    l10n.passwordResetWizardStepOtp,
    l10n.passwordResetWizardStepPassword,
  ];
}

String registerProfileStepTitle(BuildContext context, RegisterAccountType type) {
  final l10n = context.l10n;
  return switch (type) {
    RegisterAccountType.parent => l10n.registerProfileParentTitle,
    RegisterAccountType.teacher => l10n.registerProfileTeacherTitle,
    RegisterAccountType.networkOwner => l10n.registerProfileNetworkTitle,
  };
}

extension RegisterAccountTypeHubL10n on RegisterAccountType {
  String hubRoleLabel(BuildContext context) {
    final l10n = context.l10n;
    return switch (this) {
      RegisterAccountType.parent => l10n.registerHubParent,
      RegisterAccountType.teacher => l10n.registerHubTeacher,
      RegisterAccountType.networkOwner => l10n.registerHubNetworkOwner,
    };
  }
}
