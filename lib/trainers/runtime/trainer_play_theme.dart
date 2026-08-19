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

/// Stage padding: safe-area on sides/bottom only.
/// Progress + menu HUD overlay the stage (web `.trainer-player__stage` + `.trainer-player__hud`).
EdgeInsets trainerPlayStagePadding(BuildContext context) {
  final padding = MediaQuery.paddingOf(context);

  return EdgeInsets.only(
    left: padding.left,
    right: padding.right,
    bottom: padding.bottom,
  );
}

/// @deprecated Use [trainerPlayStagePadding].
double trainerPlayStageTopInset(BuildContext context) => 0;

/// @deprecated Use [trainerPlayStagePadding].
double trainerPlayHudTopInset(BuildContext context) => 0;
