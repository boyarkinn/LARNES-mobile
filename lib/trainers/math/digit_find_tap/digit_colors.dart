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

const digitFieldChipColors = <Color>[
  Color(0xFF6366F1),
  Color(0xFFEF4444),
  Color(0xFF8B5CF6),
  Color(0xFFF59E0B),
  Color(0xFF10B981),
  Color(0xFF3B82F6),
  Color(0xFFEC4899),
  Color(0xFF14B8A6),
  Color(0xFFF97316),
  Color(0xFF84CC16),
  Color(0xFFA855F7),
  Color(0xFF06B6D4),
  Color(0xFFE11D48),
  Color(0xFF65A30D),
  Color(0xFFD946EF),
  Color(0xFF0EA5E9),
  Color(0xFFCA8A04),
  Color(0xFF7C3AED),
  Color(0xFFDC2626),
  Color(0xFF059669),
  Color(0xFF2563EB),
  Color(0xFFDB2777),
  Color(0xFF0891B2),
  Color(0xFFEA580C),
  Color(0xFF4D7C0F),
  Color(0xFF9333EA),
  Color(0xFF0284C7),
  Color(0xFFBE123C),
];

Color getDigitDisplayColor(int digit) {
  final normalized = digit.truncate().clamp(0, 9);
  return digitDisplayColors[normalized] ?? const Color(0xFF1F2937);
}

Color getDigitFieldChipColor(int index) {
  if (index < 0 || index >= digitFieldChipColors.length) {
    return digitFieldChipColors[index % digitFieldChipColors.length];
  }

  return digitFieldChipColors[index];
}
