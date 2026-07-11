import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/math/digit_trace/digit_paths.dart';
import 'package:larnes_mobile/trainers/math/digit_trace/digit_trace_model.dart';
import 'package:larnes_mobile/trainers/reading/letter_guides.dart';
import 'package:larnes_mobile/trainers/reading/letter_trace/letter_trace_model.dart';

List<TraceStroke> traceAlongGuide(String letter, [double noise = 0]) {
  final guide = getLetterGuidePoints(letter);

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

List<TraceStroke> topOnlyScribble() {
  return [
    List.generate(40, (index) {
      return TracePoint(
        x: 0.3 + (0.38 * index) / 39,
        y: 0.22 + math.sin(index * 0.9) * 0.015,
      );
    }),
  ];
}

void main() {
  group('letterGuideSegments', () {
    test('defines guides for every russian letter', () {
      expect(letterGuidesReady, isTrue);
      expect(letterGuideSegments.length, 31);
      expect(getLetterGuideSegments('А').length, 3);
      expect(getLetterGuideSegments('О').length, 1);
    });
  });

  group('scoreLetterTrace', () {
    test('returns null for empty input', () {
      final result = scoreLetterTrace('А', const []);

      expect(result.similarityPercent, isNull);
      expect(result.hasEnoughInk, isFalse);
    });

    test('scores a good trace on А highly', () {
      final result = scoreLetterTrace('А', traceAlongGuide('А'));

      expect(result.similarityPercent, isNotNull);
      expect(result.similarityPercent!, greaterThanOrEqualTo(passSimilarityPercent));
    });

    test('scores a good trace on О highly', () {
      final result = scoreLetterTrace('О', traceAlongGuide('О'));

      expect(result.similarityPercent, greaterThanOrEqualTo(passSimilarityPercent));
    });

    test('scores random scribble low on А', () {
      final result = scoreLetterTrace('А', topOnlyScribble());

      expect(result.similarityPercent, isNotNull);
      expect(result.similarityPercent!, lessThan(passSimilarityPercent));
    });

    test('accepts slightly noisy tracing', () {
      final result = scoreLetterTrace('М', traceAlongGuide('М', 0.03));

      expect(result.similarityPercent, greaterThanOrEqualTo(passSimilarityPercent));
    });
  });

  group('corridorCoveragePercent on letter guides', () {
    test('returns 100 when stroke follows the reference path', () {
      final reference = resamplePolyline(getLetterGuidePoints('Т'), 32);
      final coverage = corridorCoveragePercent(reference, [reference]);

      expect(coverage, 100);
    });
  });
}
