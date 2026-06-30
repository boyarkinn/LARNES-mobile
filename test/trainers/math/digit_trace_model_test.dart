import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/math/digit_trace/digit_guides.dart';
import 'package:larnes_mobile/trainers/math/digit_trace/digit_trace_model.dart';

List<TraceStroke> traceAlongGuide(int digit, [double noise = 0]) {
  final guide = getDigitGuidePoints(digit);

  return [
    guide
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

  group('normalizePath', () {
    test('centers path in unit box', () {
      final normalized = normalizePath(const [
        TracePoint(x: 0, y: 0),
        TracePoint(x: 2, y: 2),
      ]);

      expect(normalized.every((point) => point.x >= 0 && point.x <= 1), isTrue);
      expect(normalized.every((point) => point.y >= 0 && point.y <= 1), isTrue);
    });
  });

  group('distanceToSimilarityPercent', () {
    test('returns 100 for zero distance', () {
      expect(distanceToSimilarityPercent(0), 100);
    });

    test('returns 0 at scale distance', () {
      expect(distanceToSimilarityPercent(0.42), 0);
    });
  });

  group('scoreTrace', () {
    test('returns null for empty input', () {
      final result = scoreTrace(5, const []);

      expect(result.similarityPercent, isNull);
      expect(result.hasEnoughInk, isFalse);
    });

    test('scores a good trace highly', () {
      final result = scoreTrace(5, traceAlongGuide(5));

      expect(result.similarityPercent, isNotNull);
      expect(result.similarityPercent!, greaterThanOrEqualTo(80));
    });

    test('scores a good trace on digit 2 highly', () {
      final result = scoreTrace(2, traceAlongGuide(2));

      expect(result.similarityPercent!, greaterThanOrEqualTo(80));
    });

    test('scores top-only scribble low on digit 5', () {
      final result = scoreTrace(5, topOnlyScribbleOnFive());

      expect(result.similarityPercent, isNotNull);
      expect(result.similarityPercent!, lessThan(40));
    });

    test('scores vertical zigzag low on digit 5', () {
      final result = scoreTrace(5, verticalZigzagOnFive());

      expect(result.similarityPercent, isNotNull);
      expect(result.similarityPercent!, lessThan(40));
    });

    test('accepts slightly noisy tracing', () {
      final result = scoreTrace(1, traceAlongGuide(1, 0.03));

      expect(result.similarityPercent!, greaterThanOrEqualTo(65));
    });
  });

  group('dtwAverageDistance', () {
    test('is zero for identical paths', () {
      final path = normalizePath(resamplePolyline(getDigitGuidePoints(3), 24));
      final distance = dtwAverageDistance(path, path);

      expect(distance, 0);
    });
  });
}
