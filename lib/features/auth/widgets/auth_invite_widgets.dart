import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:larnes_mobile/features/auth/theme/auth_theme.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_buttons.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_header.dart';

class AuthInviteContextCard extends StatelessWidget {
  const AuthInviteContextCard({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AuthColors.surfaceStrong,
        borderRadius: BorderRadius.circular(AuthRadii.input),
        border: Border.all(color: const Color.fromRGBO(26, 29, 46, 0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: RichText(
          text: TextSpan(
            style: GoogleFonts.inter(
              fontSize: 14,
              height: 1.45,
              color: AuthColors.ink,
            ),
            children: [
              TextSpan(
                text: '$label: ',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              TextSpan(text: value),
            ],
          ),
        ),
      ),
    );
  }
}

class AuthInviteActions extends StatelessWidget {
  const AuthInviteActions({
    super.key,
    required this.declineLabel,
    required this.acceptLabel,
    required this.onDecline,
    required this.onAccept,
    this.isLoading = false,
  });

  final String declineLabel;
  final String acceptLabel;
  final VoidCallback? onDecline;
  final VoidCallback? onAccept;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AuthSecondaryButton(
            label: declineLabel,
            isLoading: isLoading,
            onPressed: onDecline,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: AuthPrimaryButton(
            label: acceptLabel,
            isLoading: isLoading,
            useWebAuthStyle: true,
            onPressed: onAccept,
          ),
        ),
      ],
    );
  }
}

class AuthInviteLoginGate extends StatelessWidget {
  const AuthInviteLoginGate({
    super.key,
    required this.loginLabel,
    required this.onLogin,
    required this.registerLead,
    required this.registerLabel,
    required this.onRegister,
  });

  final String loginLabel;
  final VoidCallback onLogin;
  final String registerLead;
  final String registerLabel;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthPrimaryButton(
          label: loginLabel,
          useWebAuthStyle: true,
          onPressed: onLogin,
        ),
        AuthFormFoot(
          leadText: registerLead,
          linkLabel: registerLabel,
          onLinkPressed: onRegister,
        ),
      ],
    );
  }
}
