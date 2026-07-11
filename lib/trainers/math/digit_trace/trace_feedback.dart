import 'package:flutter/material.dart';

/// Web v2: `platform/src/trainers/math/digit-trace/trace-feedback.ts`

const tracePassPercent = 75;
const traceAmberPercent = 45;

Color getTraceStrokeColor(
  int? similarityPercent,
  Color digitColor, {
  bool isDrawing = false,
}) {
  if (similarityPercent == null || isDrawing) {
    return digitColor;
  }

  if (similarityPercent >= tracePassPercent) {
    return const Color(0xFF22C55E);
  }

  if (similarityPercent >= traceAmberPercent) {
    return const Color(0xFFF59E0B);
  }

  return const Color(0xFFEF4444);
}
