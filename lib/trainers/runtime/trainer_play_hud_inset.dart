import 'package:flutter/material.dart';

/// Зазор между HUD «Меню» и контентом сцены (web `TRAINER_PLAY_HUD_SIDE_INSET_GAP_PX`).
const double trainerPlayHudSideInsetGap = 8;

/// Горизонтальный отступ match-board от кнопки «Меню» (симметрично слева/справа).
///
/// Повторяет раскладку [TrainerPlayShell] + [TrainerPlayerMenuButton]:
/// SafeArea слева, затем `max(14, safeLeft)` и кнопка 48×48.
double computeTrainerPlayHudSideInset(BuildContext context) {
  final safeLeft = MediaQuery.paddingOf(context).left;
  const menuButtonPaddingLeft = 14.0;
  const menuButtonSize = 48.0;

  final menuRightFromScreen = safeLeft + menuButtonPaddingLeft + menuButtonSize;
  final boardLeftFromScreen = safeLeft;
  final inset = menuRightFromScreen - boardLeftFromScreen + trainerPlayHudSideInsetGap;

  return inset.clamp(0.0, double.infinity);
}
