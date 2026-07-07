import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';
import 'package:larnes_mobile/features/parent/widgets/account/desk_text_field.dart';

typedef AuthTextField = DeskTextField;

class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({super.key, required this.message});

  final String message;

  static const _red = Color(0xFFDC2626);
  static const _redBg = Color(0xFFFEF2F2);
  static const _redBorder = Color.fromRGBO(220, 38, 38, 0.25);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _redBg,
        borderRadius: BorderRadius.circular(ParentRadii.card),
        border: Border.all(color: _redBorder),
      ),
      child: Text(
        message,
        style: GoogleFonts.onest(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: _red,
          height: 1.35,
        ),
      ),
    );
  }
}

class AuthSuccessBanner extends StatelessWidget {
  const AuthSuccessBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: ParentColors.shellSoft,
        borderRadius: BorderRadius.circular(ParentRadii.card),
        border: Border.all(color: ParentColors.shell.withValues(alpha: 0.25)),
      ),
      child: Text(
        message,
        style: GoogleFonts.onest(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: ParentColors.shellDeep,
          height: 1.35,
        ),
      ),
    );
  }
}
