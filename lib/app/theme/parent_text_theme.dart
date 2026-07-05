import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';

/// Fredoka (display) + Onest (body) — как web `(parent)/layout.tsx`.
TextTheme buildParentTextTheme() {
  final onest = GoogleFonts.onest(
    fontWeight: FontWeight.w500,
    color: ParentColors.ink,
  );
  final onestSemi = GoogleFonts.onest(
    fontWeight: FontWeight.w600,
    color: ParentColors.ink,
  );
  final fredoka = GoogleFonts.fredoka(
    fontWeight: FontWeight.w600,
    color: ParentColors.ink,
  );

  return TextTheme(
    headlineMedium: fredoka.copyWith(fontSize: 19, letterSpacing: -0.01 * 19),
    titleLarge: fredoka.copyWith(fontSize: 20, letterSpacing: -0.015 * 20),
    titleMedium: onestSemi.copyWith(fontSize: 17),
    bodyLarge: onest.copyWith(fontSize: 16, height: 1.4),
    bodyMedium: onest.copyWith(fontSize: 14, height: 1.4, color: ParentColors.inkMuted),
    labelLarge: onestSemi.copyWith(fontSize: 16),
  );
}
