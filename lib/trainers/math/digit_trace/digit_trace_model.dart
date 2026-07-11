import 'dart:math' as math;

import 'package:larnes_mobile/trainers/math/digit_trace/digit_paths.dart';

/// Web v2: `platform/src/trainers/math/digit-trace/model.ts`

typedef TraceStroke = List<TracePoint>;

const referenceSampleCount = 64;
const corridorRadius = 0.095;
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

    while (segmentIndex < cumulative.length && cumulative[segmentIndex] < target) {
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

double _distancePointToSegment(
  TracePoint point,
  TracePoint segmentStart,
  TracePoint segmentEnd,
) {
  final dx = segmentEnd.x - segmentStart.x;
  final dy = segmentEnd.y - segmentStart.y;
  final lengthSquared = dx * dx + dy * dy;

  if (lengthSquared == 0) {
    return _distance(point, segmentStart);
  }

  final projection =
      ((point.x - segmentStart.x) * dx + (point.y - segmentStart.y) * dy) /
          lengthSquared;
  final clamped = math.max(0, math.min(1, projection));
  final projectedX = segmentStart.x + clamped * dx;
  final projectedY = segmentStart.y + clamped * dy;

  return _distance(point, TracePoint(x: projectedX, y: projectedY));
}

double _distancePointToStrokes(TracePoint point, List<TraceStroke> strokes) {
  var minDistance = double.infinity;

  for (final stroke in strokes) {
    for (var index = 1; index < stroke.length; index++) {
      final segmentDistance = _distancePointToSegment(
        point,
        stroke[index - 1],
        stroke[index],
      );
      minDistance = math.min(minDistance, segmentDistance);
    }
  }

  return minDistance;
}

int corridorCoveragePercent(
  List<TracePoint> referencePoints,
  List<TraceStroke> strokes, {
  double radius = corridorRadius,
}) {
  if (referencePoints.isEmpty) {
    return 0;
  }

  var hits = 0;

  for (final point in referencePoints) {
    if (_distancePointToStrokes(point, strokes) <= radius) {
      hits++;
    }
  }

  return ((100 * hits) / referencePoints.length).round();
}

TraceScore scoreTrace(int digit, List<TraceStroke> strokes) {
  final strokeLength = getStrokeLength(strokes);

  if (flattenStrokes(strokes).length < 2 || strokeLength < minScoreStrokeLength) {
    return TraceScore(
      hasEnoughInk: false,
      similarityPercent: null,
      strokeLength: strokeLength,
    );
  }

  final reference = getDigitReferenceSamples(digit, referenceSampleCount);

  return TraceScore(
    hasEnoughInk: true,
    similarityPercent: corridorCoveragePercent(reference, strokes),
    strokeLength: strokeLength,
  );
}

double _distance(TracePoint a, TracePoint b) {
  final dx = a.x - b.x;
  final dy = a.y - b.y;
  return math.sqrt(dx * dx + dy * dy);
}
