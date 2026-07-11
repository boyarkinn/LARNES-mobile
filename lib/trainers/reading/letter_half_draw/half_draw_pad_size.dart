import 'dart:ui';

import 'package:larnes_mobile/trainers/math/digit_trace/trace_pad_size.dart';
import 'package:larnes_mobile/trainers/reading/letter_half_draw/half_draw_model.dart';

/// Web: `platform/src/trainers/reading/letter-half-draw/half-draw-pad-size.ts`

const halfDrawFixedLetterColor = Color(0xFF475569);
const halfDrawSplitLineColor = Color(0xFFCBD5E1);
const halfDrawBurstColor = Color(0xFF22C55E);

double halfDrawPadSize(double viewportHeight, double viewportWidth) {
  return tracePadSize(viewportHeight, viewportWidth);
}

double halfDrawSplitLineViewboxX() {
  return halfDrawViewboxSize / 2;
}
