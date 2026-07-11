import 'package:flutter/material.dart';
import 'package:larnes_mobile/app/theme/admin_theme.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';

/// Visual tokens for [TrainerPlayShell] (web `.trainer-player__*`).
enum TrainerPlayThemeKind { parent, admin }

class TrainerPlayTheme {
  const TrainerPlayTheme._({
    required this.accent,
    required this.accentDeep,
    required this.accentPressed,
    required this.progressTrack,
    required this.danger,
    required this.dangerPressed,
  });

  final Color accent;
  final Color accentDeep;
  final Color accentPressed;
  final Color progressTrack;
  final Color danger;
  final Color dangerPressed;

  static const parent = TrainerPlayTheme._(
    accent: ParentColors.shell,
    accentDeep: ParentColors.shellDeep,
    accentPressed: Color(0xFF244DB0),
    progressTrack: Color.fromRGBO(26, 29, 46, 0.1),
    danger: Color(0xFFDC2626),
    dangerPressed: Color(0xFFB91C1C),
  );

  static const admin = TrainerPlayTheme._(
    accent: AdminColors.accent,
    accentDeep: AdminColors.accentDeep,
    accentPressed: AdminColors.accentDeep,
    progressTrack: Color.fromRGBO(26, 29, 46, 0.1),
    danger: Color(0xFFDC2626),
    dangerPressed: Color(0xFFB91C1C),
  );

  static TrainerPlayTheme forKind(TrainerPlayThemeKind kind) {
    return switch (kind) {
      TrainerPlayThemeKind.parent => parent,
      TrainerPlayThemeKind.admin => admin,
    };
  }
}

/// Top inset so trainer content clears HUD (progress + menu).
double trainerPlayHudTopInset(BuildContext context) {
  final safeTop = MediaQuery.paddingOf(context).top;
  const progressHeight = 7.0;
  const menuGap = 12.0;
  const menuButtonSize = 48.0;
  return safeTop + progressHeight + menuGap + menuButtonSize;
}
