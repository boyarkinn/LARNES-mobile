import 'dart:math' as math;

import 'package:larnes_mobile/trainers/math/digit_trace/digit_guides.dart';

typedef TraceStroke = List<TracePoint>;

const resamplePointCount = 48;
const scoreDistanceScale = 0.42;
const minScoreStrokeLength = 0.05;

class TraceScore {
  const TraceScore({
    required this.similarityPercent,
    required this.strokeLength,
    required this.hasEnoughInk,
  });

  final int? similarityPercent;
  final double strokeLength;
  final bool hasEnoughInk;
}

List<TracePoint> flattenStrokes(List<TraceStroke> strokes) {
  return strokes.expand((stroke) => stroke).toList();
}

double getStrokeLength(List<TraceStroke> strokes) {
  var length = 0.0;

  for (final stroke in strokes) {
    for (var index = 1; index < stroke.length; index++) {
      length += _distance(stroke[index - 1], stroke[index]);
    }
  }

  return length;
}

List<TracePoint> resamplePolyline(List<TracePoint> points, int targetCount) {
  if (points.isEmpty) {
    return const [];
  }

  if (points.length == 1) {
    return List.generate(targetCount, (_) => points[0]);
  }

  final cumulative = <double>[0];

  for (var index = 1; index < points.length; index++) {
    cumulative.add(cumulative[index - 1] + _distance(points[index - 1], points[index]));
  }

  final totalLength = cumulative.last;

  if (totalLength == 0) {
    return List.generate(targetCount, (_) => points[0]);
  }

  final resampled = <TracePoint>[];

  for (var index = 0; index < targetCount; index++) {
    final target = (index / (targetCount - 1)) * totalLength;
    var segmentIndex = 1;

    while (segmentIndex < cumulative.length &&
        cumulative[segmentIndex] < target) {
      segmentIndex++;
    }

    final start = points[segmentIndex - 1];
    final end = points[math.min(segmentIndex, points.length - 1)];
    final segmentStart = cumulative[segmentIndex - 1];
    final segmentLength = cumulative[segmentIndex] - segmentStart;
    final t = (target - segmentStart) / (segmentLength == 0 ? 1 : segmentLength);

    resampled.add(
      TracePoint(
        x: start.x + (end.x - start.x) * t,
        y: start.y + (end.y - start.y) * t,
      ),
    );
  }

  return resampled;
}

List<TracePoint> normalizePath(List<TracePoint> points) {
  if (points.isEmpty) {
    return const [];
  }

  var minX = double.infinity;
  var minY = double.infinity;
  var maxX = -double.infinity;
  var maxY = -double.infinity;

  for (final point in points) {
    minX = math.min(minX, point.x);
    minY = math.min(minY, point.y);
    maxX = math.max(maxX, point.x);
    maxY = math.max(maxY, point.y);
  }

  final width = maxX - minX;
  final height = maxY - minY;
  final scale = math.max(width, math.max(height, 1e-6));
  final centerX = (minX + maxX) / 2;
  final centerY = (minY + maxY) / 2;

  return points
      .map(
        (point) => TracePoint(
          x: (point.x - centerX) / scale + 0.5,
          y: (point.y - centerY) / scale + 0.5,
        ),
      )
      .toList();
}

double dtwAverageDistance(List<TracePoint> a, List<TracePoint> b) {
  final n = a.length;
  final m = b.length;

  if (n == 0 || m == 0) {
    return scoreDistanceScale;
  }

  final dp = List.generate(n, (_) => List<double>.filled(m, 0));

  dp[0][0] = _distance(a[0], b[0]);

  for (var i = 0; i < n; i++) {
    for (var j = 0; j < m; j++) {
      if (i == 0 && j == 0) {
        continue;
      }

      final cost = _distance(a[i], b[j]);
      var best = double.infinity;

      if (i > 0) {
        best = math.min(best, dp[i - 1][j]);
      }
      if (j > 0) {
        best = math.min(best, dp[i][j - 1]);
      }
      if (i > 0 && j > 0) {
        best = math.min(best, dp[i - 1][j - 1]);
      }

      dp[i][j] = cost + best;
    }
  }

  return dp[n - 1][m - 1] / math.max(n, m);
}

int distanceToSimilarityPercent(double avgDistance) {
  final ratio = avgDistance / scoreDistanceScale;
  final score = (100 * math.max(0, 1 - ratio)).round();

  return math.min(100, score);
}

TraceScore scoreTrace(int digit, List<TraceStroke> strokes) {
  final drawn = flattenStrokes(strokes);
  final reference = getDigitGuidePoints(digit);
  final strokeLength = getStrokeLength(strokes);

  if (drawn.length < 2 || strokeLength < minScoreStrokeLength) {
    return TraceScore(
      hasEnoughInk: false,
      similarityPercent: null,
      strokeLength: strokeLength,
    );
  }

  final userPath =
      normalizePath(resamplePolyline(drawn, resamplePointCount));
  final referencePath =
      normalizePath(resamplePolyline(reference, resamplePointCount));
  final avgDistance = dtwAverageDistance(userPath, referencePath);

  return TraceScore(
    hasEnoughInk: true,
    similarityPercent: distanceToSimilarityPercent(avgDistance),
    strokeLength: strokeLength,
  );
}

double _distance(TracePoint a, TracePoint b) {
  final dx = a.x - b.x;
  final dy = a.y - b.y;
  return math.sqrt(dx * dx + dy * dy);
}
