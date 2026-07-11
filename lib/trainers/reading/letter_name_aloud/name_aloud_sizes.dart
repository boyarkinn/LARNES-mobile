import 'dart:math' as math;
import 'dart:ui';

import 'package:larnes_mobile/trainers/math/digit_trace/trace_pad_size.dart';

/// Web: `platform/src/trainers/reading/letter-name-aloud/name-aloud-sizes.ts`

const nameAloudProgressDoneColor = Color(0xFF16A34A);
const nameAloudProgressPendingColor = Color(0xFFCBD5E1);

const nameAloudDisplayPulseMs = 2400;
const nameAloudSettlePulseMs = 600;
const nameAloudCompleteDelayMs = 180;
const nameAloudFinishDelayMs =
    nameAloudSettlePulseMs + nameAloudCompleteDelayMs;

const _letterFontHeightFraction = 0.48;
const _letterFontMaxWidthFraction = 0.40;

double nameAloudBoxSize(double viewportHeight, double viewportWidth) {
  return tracePadSize(viewportHeight, viewportWidth);
}

double nameAloudLetterFontSize(double viewportHeight, double viewportWidth) {
  if (!viewportHeight.isFinite ||
      viewportHeight <= 0 ||
      !viewportWidth.isFinite ||
      viewportWidth <= 0) {
    return 192;
  }

  return math
      .min(
        viewportHeight * _letterFontHeightFraction,
        viewportWidth * _letterFontMaxWidthFraction,
      )
      .roundToDouble();
}
