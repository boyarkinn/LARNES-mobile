import 'package:flutter/material.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_header.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_scaffold.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_stepper.dart';

class AuthWebFlowShell extends StatelessWidget {
  const AuthWebFlowShell({
    super.key,
    required this.child,
    this.showBackButton = true,
    this.onBack,
    this.stepLabels,
    this.currentStep = 1,
    this.stepTitle,
  });

  final Widget child;
  final bool showBackButton;
  final VoidCallback? onBack;
  final List<String>? stepLabels;
  final int currentStep;
  final String? stepTitle;

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      variant: AuthScaffoldVariant.web,
      showBackButton: showBackButton,
      onBack: onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (stepLabels != null && stepLabels!.isNotEmpty)
            AuthStepper(current: currentStep, labels: stepLabels!),
          if (stepTitle != null && stepTitle!.isNotEmpty)
            AuthCompactKicker(text: stepTitle!),
          child,
        ],
      ),
    );
  }
}
