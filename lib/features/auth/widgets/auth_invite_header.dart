import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:larnes_mobile/features/auth/theme/auth_theme.dart';
import 'package:larnes_mobile/features/auth/widgets/auth_scaffold.dart';

class AuthInviteHeader extends StatelessWidget {
  const AuthInviteHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.claim = false,
  });

  final String title;
  final String? subtitle;
  final bool claim;

  @override
  Widget build(BuildContext context) {
    final titleStyle = claim
        ? GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
            height: 1.2,
            color: AuthColors.cobalt,
          )
        : GoogleFonts.inter(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.1,
            height: 1.05,
            color: AuthColors.cobalt,
          );

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            claim ? title : title.toUpperCase(),
            textAlign: TextAlign.center,
            style: titleStyle,
          ),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.55,
                color: AuthColors.muted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class AuthInviteShell extends StatelessWidget {
  const AuthInviteShell({
    super.key,
    required this.title,
    this.subtitle,
    this.claim = false,
    required this.child,
    this.showBackButton = false,
    this.onBack,
  });

  final String title;
  final String? subtitle;
  final bool claim;
  final Widget child;
  final bool showBackButton;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      variant: AuthScaffoldVariant.web,
      showBackButton: showBackButton,
      onBack: onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthInviteHeader(title: title, subtitle: subtitle, claim: claim),
          child,
        ],
      ),
    );
  }
}
