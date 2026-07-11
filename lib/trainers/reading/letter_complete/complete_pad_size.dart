import 'package:flutter/material.dart';

import 'package:larnes_mobile/trainers/math/digit_trace/trace_pad_size.dart';

/// Web: `platform/src/trainers/reading/letter-complete/complete-pad-size.ts`

const completeInkColor = Color(0xFF475569);
const completeFixedStrokeColor = Color(0xFF64748B);
const completeMissingDashColor = Color(0xFFCBD5E1);
const completeBurstColor = Color(0xFF22C55E);

double completePadSize(double viewportHeight, double viewportWidth) {
  return tracePadSize(viewportHeight, viewportWidth);
}
