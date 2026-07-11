import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/math/digit_trace/trace_feedback.dart';

void main() {
  group('trace-feedback', () {
    const digitColor = Color(0xFF8B5CF6);

    test('uses digit color while drawing', () {
      expect(
        getTraceStrokeColor(null, digitColor, isDrawing: true),
        digitColor,
      );
    });

    test('uses green at pass threshold', () {
      expect(
        getTraceStrokeColor(tracePassPercent, digitColor),
        const Color(0xFF22C55E),
      );
    });

    test('uses amber between amber and pass thresholds', () {
      expect(
        getTraceStrokeColor(traceAmberPercent, digitColor),
        const Color(0xFFF59E0B),
      );
    });

    test('uses red below amber threshold', () {
      expect(
        getTraceStrokeColor(traceAmberPercent - 1, digitColor),
        const Color(0xFFEF4444),
      );
    });
  });
}
