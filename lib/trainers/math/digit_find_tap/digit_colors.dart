/// Web v2: `platform/src/trainers/math/digit-find-tap/digit-colors.ts`

import 'package:flutter/material.dart';

const digitDisplayColors = <int, Color>{
  0: Color(0xFF6366F1),
  1: Color(0xFFEF4444),
  2: Color(0xFF8B5CF6),
  3: Color(0xFFF59E0B),
  4: Color(0xFF10B981),
  5: Color(0xFF3B82F6),
  6: Color(0xFFEC4899),
  7: Color(0xFF14B8A6),
  8: Color(0xFFF97316),
  9: Color(0xFF84CC16),
};

Color getDigitDisplayColor(int digit) {
  final normalized = digit.truncate().clamp(0, 9);
  return digitDisplayColors[normalized] ?? const Color(0xFF1F2937);
}
