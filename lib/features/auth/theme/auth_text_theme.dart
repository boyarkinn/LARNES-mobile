import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:larnes_mobile/features/auth/theme/auth_theme.dart';

TextTheme buildAuthTextTheme() {
  final base = GoogleFonts.interTextTheme();
  return base.copyWith(
    bodyLarge: GoogleFonts.inter(
      fontSize: 15,
      fontWeight: FontWeight.w400,
      height: 1.45,
      color: AuthColors.ink,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      height: 1.4,
      color: AuthColors.muted,
    ),
    labelLarge: GoogleFonts.inter(
      fontSize: 15,
      fontWeight: FontWeight.w700,
      color: AuthColors.ink,
    ),
  );
}
