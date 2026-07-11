import 'dart:math' as math;
import 'dart:ui';

import 'package:larnes_mobile/trainers/math/digit_trace/digit_paths.dart';
import 'package:larnes_mobile/trainers/math/digit_trace/digit_trace_model.dart';
import 'package:larnes_mobile/trainers/math/digit_trace/trace_feedback.dart';
import 'package:larnes_mobile/trainers/reading/letter_guides.dart';
import 'package:larnes_mobile/trainers/reading/letter_model.dart';

export 'package:larnes_mobile/trainers/math/digit_trace/digit_trace_model.dart'
    show TraceScore, TraceStroke;

/// Web: `platform/src/trainers/reading/letter-half-draw/model.ts`

const halfSplit = 0.5;
const halfDrawViewboxSize = 100.0;
const passSimilarityPercent = tracePassPercent;
const minRightHalfInkLength = minScoreStrokeLength;

double _pointDistance(TracePoint a, TracePoint b) {
  return math.sqrt(math.pow(a.x - b.x, 2) + math.pow(a.y - b.y, 2));
}

TracePoint _interpolateAtX(TracePoint a, TracePoint b, double split) {
  if ((b.x - a.x).abs() < 1e-9) {
    return TracePoint(x: split, y: (a.y + b.y) / 2);
  }

  final t = (split - a.x) / (b.x - a.x);

  return TracePoint(
    x: split,
    y: a.y + (b.y - a.y) * t,
  );
}

List<TracePoint> _dedupePoints(List<TracePoint> points) {
  if (points.isEmpty) {
    return const [];
  }

  final deduped = <TracePoint>[points.first];

  for (var index = 1; index < points.length; index++) {
    if (_pointDistance(points[index], deduped.last) > 0.002) {
      deduped.add(points[index]);
    }
  }

  return deduped;
}

List<TracePoint> clipSegmentToRightHalf(
  List<TracePoint> points, {
  double split = halfSplit,
}) {
  if (points.isEmpty) {
    return const [];
  }

  final clipped = <TracePoint>[];

  for (var index = 1; index < points.length; index++) {
    final start = points[index - 1];
    final end = points[index];
    final startInside = start.x >= split;
    final endInside = end.x >= split;

    if (startInside && endInside) {
      if (clipped.isEmpty || _pointDistance(clipped.last, start) > 0.002) {
        clipped.add(start);
      }

      clipped.add(end);
      continue;
    }

    if (!startInside && endInside) {
      clipped.add(_interpolateAtX(start, end, split));
      clipped.add(end);
      continue;
    }

    if (startInside && !endInside) {
      clipped.add(_interpolateAtX(start, end, split));
    }
  }

  if (points.length == 1 && points.first.x >= split) {
    return [points.first];
  }

  return _dedupePoints(clipped);
}

List<TracePoint> getRightHalfReferencePoints(String letter) {
  final segments = getLetterGuideSegments(normalizeTargetLetter(letter));

  return _dedupePoints(
    segments.expand(clipSegmentToRightHalf).toList(),
  );
}

List<TraceStroke> filterStrokesToRightHalf(
  List<TraceStroke> strokes, {
  double split = halfSplit,
}) {
  return [
    for (final stroke in strokes)
      if (stroke.where((point) => point.x >= split).length >= 2)
        [for (final point in stroke)
          if (point.x >= split) point],
  ];
}

double getRightHalfStrokeLength(List<TraceStroke> strokes) {
  return getStrokeLength(filterStrokesToRightHalf(strokes));
}

TraceScore scoreLetterHalfDraw(String letter, List<TraceStroke> strokes) {
  final reference = getRightHalfReferencePoints(letter);
  final rightStrokes = filterStrokesToRightHalf(strokes);
  final strokeLength = getRightHalfStrokeLength(strokes);

  if (strokeLength < minRightHalfInkLength || reference.length < 2) {
    return TraceScore(
      hasEnoughInk: strokeLength >= minRightHalfInkLength,
      similarityPercent: strokeLength >= minRightHalfInkLength && reference.length < 2
          ? passSimilarityPercent
          : null,
      strokeLength: strokeLength,
    );
  }

  final referenceSamples = resamplePolyline(reference, referenceSampleCount);

  return TraceScore(
    hasEnoughInk: true,
    similarityPercent: corridorCoveragePercent(referenceSamples, rightStrokes),
    strokeLength: strokeLength,
  );
}

bool isSuccessfulHalfDraw(TraceScore score) {
  return score.similarityPercent != null &&
      score.similarityPercent! >= passSimilarityPercent;
}

bool isPointInDrawableHalf(
  Offset viewboxPoint, {
  double splitViewbox = halfDrawViewboxSize / 2,
}) {
  return viewboxPoint.dx >= splitViewbox;
}

TracePoint toNormalizedPoint(Offset point) {
  return TracePoint(
    x: point.dx / halfDrawViewboxSize,
    y: point.dy / halfDrawViewboxSize,
  );
}

Offset toViewboxPoint(TracePoint point) {
  return Offset(
    point.x * halfDrawViewboxSize,
    point.y * halfDrawViewboxSize,
  );
}
