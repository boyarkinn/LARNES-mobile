import 'dart:math' as math;
import 'dart:ui';

import 'package:larnes_mobile/trainers/reading/letter_draw_show/draw_show_model.dart';

/// Web: `platform/src/trainers/reading/letter-draw-show/draw-show-sizes.ts`

const drawShowMaxHeightSvhFraction = 0.72;
const drawShowMaxWidthVwFraction = 0.96;

const drawSettlePulseMs = 2400;

const drawRoundDoneColor = Color(0xFF16A34A);
const drawRoundPendingColor = Color(0xFFCBD5E1);

const drawFinishDelayMs = drawSettlePulseMs + drawShowCompleteDelayMs;

double drawShowBoxSize(double viewportHeight, double viewportWidth) {
  if (!viewportHeight.isFinite ||
      viewportHeight <= 0 ||
      !viewportWidth.isFinite ||
      viewportWidth <= 0) {
    return 192;
  }

  return math
      .min(
        viewportHeight * drawShowMaxHeightSvhFraction,
        viewportWidth * drawShowMaxWidthVwFraction,
      )
      .roundToDouble();
}
