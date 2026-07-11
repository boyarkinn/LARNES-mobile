import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/math/digit_trace/digit_paths.dart';
import 'package:larnes_mobile/trainers/math/digit_trace/digit_trace_model.dart';

List<TraceStroke> traceAlongReference(int digit, [double noise = 0]) {
  final reference = getDigitReferenceSamples(digit, referenceSampleCount);

  return [
    reference
        .map(
          (point) => TracePoint(
            x: point.x + noise,
            y: point.y + noise,
          ),
        )
        .toList(),
  ];
}

List<TraceStroke> topOnlyScribbleOnFive() {
  return [
    List.generate(40, (index) {
      return TracePoint(
        x: 0.3 + (0.38 * index) / 39,
        y: 0.22 + math.sin(index * 0.9) * 0.015,
      );
    }),
  ];
}

List<TraceStroke> verticalZigzagOnFive() {
  return [
    List.generate(50, (index) {
      return TracePoint(
        x: 0.48 + math.sin(index * 0.8) * 0.04,
        y: 0.18 + (0.62 * index) / 49,
      );
    }),
  ];
}

void main() {
  group('resamplePolyline', () {
    test('returns requested number of points', () {
      final points = resamplePolyline(
        const [
          TracePoint(x: 0, y: 0),
          TracePoint(x: 1, y: 0),
        ],
        12,
      );

      expect(points.length, 12);
    });
  });

  group('corridorCoveragePercent', () {
    test('returns 100 when stroke follows the reference path', () {
      final reference = getDigitReferenceSamples(2, 32);
      final coverage = corridorCoveragePercent(reference, traceAlongReference(2));

      expect(coverage, 100);
    });

    test('returns 0 when stroke is far from the reference', () {
      final reference = getDigitReferenceSamples(2, 32);
      final coverage = corridorCoveragePercent(reference, const [
        [
          TracePoint(x: 0.05, y: 0.05),
          TracePoint(x: 0.1, y: 0.1),
        ],
      ]);

      expect(coverage, 0);
    });
  });

  group('scoreTrace', () {
    test('returns null for empty input', () {
      final result = scoreTrace(5, const []);

      expect(result.similarityPercent, isNull);
      expect(result.hasEnoughInk, isFalse);
    });

    test('scores a good trace highly', () {
      final result = scoreTrace(5, traceAlongReference(5));

      expect(result.similarityPercent, isNotNull);
      expect(result.similarityPercent!, greaterThanOrEqualTo(90));
    });

    test('scores a good trace on digit 2 highly', () {
      final result = scoreTrace(2, traceAlongReference(2));

      expect(result.similarityPercent!, greaterThanOrEqualTo(90));
    });

    test('scores top-only scribble low on digit 5', () {
      final result = scoreTrace(5, topOnlyScribbleOnFive());

      expect(result.similarityPercent, isNotNull);
      expect(result.similarityPercent!, lessThan(50));
    });

    test('scores vertical zigzag low on digit 5', () {
      final result = scoreTrace(5, verticalZigzagOnFive());

      expect(result.similarityPercent, isNotNull);
      expect(result.similarityPercent!, lessThan(50));
    });

    test('accepts slightly noisy tracing', () {
      final result = scoreTrace(1, traceAlongReference(1, corridorRadius * 0.25));

      expect(result.similarityPercent!, greaterThanOrEqualTo(75));
    });
  });
}
