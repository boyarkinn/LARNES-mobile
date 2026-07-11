import 'dart:math' as math;
import 'dart:ui';

/// Web v2: `platform/src/trainers/math/digit-trace/digit-paths.ts`

const digitPathViewboxSize = 100.0;

class TracePoint {
  const TracePoint({required this.x, required this.y});

  final double x;
  final double y;

  TracePoint copyWith({double? x, double? y}) {
    return TracePoint(x: x ?? this.x, y: y ?? this.y);
  }
}

double _pointDistance(TracePoint a, TracePoint b) {
  final dx = a.x - b.x;
  final dy = a.y - b.y;
  return math.sqrt(dx * dx + dy * dy);
}

List<TracePoint> _resamplePolyline(List<TracePoint> points, int targetCount) {
  if (points.isEmpty) {
    return const [];
  }

  if (points.length == 1) {
    return List.generate(targetCount, (_) => points[0]);
  }

  final cumulative = <double>[0];

  for (var index = 1; index < points.length; index++) {
    cumulative.add(cumulative[index - 1] + _pointDistance(points[index - 1], points[index]));
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

List<TracePoint> _line(
  double x1,
  double y1,
  double x2,
  double y2,
  int steps,
) {
  final points = <TracePoint>[];

  for (var index = 0; index <= steps; index++) {
    final t = index / steps;
    points.add(
      TracePoint(
        x: x1 + (x2 - x1) * t,
        y: y1 + (y2 - y1) * t,
      ),
    );
  }

  return points;
}

List<TracePoint> _arc(
  double cx,
  double cy,
  double radius,
  double startAngle,
  double endAngle,
  int steps,
) {
  final points = <TracePoint>[];

  for (var index = 0; index <= steps; index++) {
    final t = index / steps;
    final angle = startAngle + (endAngle - startAngle) * t;
    points.add(
      TracePoint(
        x: cx + radius * math.cos(angle),
        y: cy + radius * math.sin(angle),
      ),
    );
  }

  return points;
}

final _path0 = [_arc(0.5, 0.52, 0.24, 0, math.pi * 2, 36)];

final _path1 = [
  _line(0.45, 0.28, 0.52, 0.2, 6),
  _line(0.52, 0.2, 0.52, 0.82, 24),
];

final _path2 = [
  _arc(0.58, 0.3, 0.2, math.pi, math.pi * 2.15, 14),
  _line(0.38, 0.3, 0.72, 0.78, 14),
  _line(0.28, 0.78, 0.74, 0.78, 12),
];

final _path3 = [
  _arc(0.52, 0.3, 0.2, math.pi * 0.85, math.pi * 2.2, 14),
  _arc(0.52, 0.58, 0.2, math.pi * 1.1, math.pi * 2.35, 14),
];

final _path4 = [
  _line(0.62, 0.22, 0.34, 0.58, 14),
  _line(0.34, 0.58, 0.72, 0.58, 12),
  _line(0.62, 0.22, 0.62, 0.8, 16),
];

final _path5 = [
  _line(0.68, 0.22, 0.32, 0.22, 10),
  _line(0.32, 0.22, 0.3, 0.46, 10),
  _arc(0.52, 0.46, 0.2, math.pi, math.pi * 2.05, 14),
  _line(0.72, 0.66, 0.3, 0.78, 12),
];

final _path6 = [
  _arc(0.5, 0.58, 0.22, math.pi * 0.35, math.pi * 2.25, 22),
  _line(0.34, 0.42, 0.34, 0.28, 8),
  _arc(0.5, 0.28, 0.16, math.pi, math.pi * 2.05, 12),
];

final _path7 = [
  _line(0.28, 0.22, 0.72, 0.22, 12),
  _line(0.72, 0.22, 0.48, 0.8, 16),
];

final _path8 = [
  _arc(0.5, 0.34, 0.18, 0, math.pi * 2, 18),
  _arc(0.5, 0.64, 0.2, 0, math.pi * 2, 20),
];

final _path9 = [
  _arc(0.5, 0.36, 0.18, 0, math.pi * 2, 18),
  _line(0.5, 0.54, 0.5, 0.8, 12),
  _line(0.36, 0.8, 0.64, 0.8, 10),
];

final _digitPathSegments = <int, List<List<TracePoint>>>{
  0: _path0,
  1: _path1,
  2: _path2,
  3: _path3,
  4: _path4,
  5: _path5,
  6: _path6,
  7: _path7,
  8: _path8,
  9: _path9,
};

double _getSubpathLength(List<TracePoint> subpath) {
  var length = 0.0;

  for (var index = 1; index < subpath.length; index++) {
    length += _pointDistance(subpath[index - 1], subpath[index]);
  }

  return length;
}

List<List<TracePoint>> getDigitPathSegments(int digit) {
  return _digitPathSegments[digit] ?? _path0;
}

Path buildDigitGuidePath(int digit, Size size) {
  final path = Path();
  final scale = size.width;

  for (final segment in getDigitPathSegments(digit)) {
    if (segment.isEmpty) {
      continue;
    }

    path.moveTo(segment.first.x * scale, segment.first.y * scale);

    for (var index = 1; index < segment.length; index++) {
      final point = segment[index];
      path.lineTo(point.x * scale, point.y * scale);
    }
  }

  return path;
}

Path buildDashedPath(Path source, {List<double> dashArray = const [6, 5]}) {
  final dashed = Path();

  for (final metric in source.computeMetrics()) {
    var distance = 0.0;
    var draw = true;
    var dashIndex = 0;

    while (distance < metric.length) {
      final dashLength = dashArray[dashIndex % dashArray.length];
      final end = math.min(distance + dashLength, metric.length);

      if (draw) {
        dashed.addPath(metric.extractPath(distance, end), Offset.zero);
      }

      distance += dashLength;
      dashIndex++;
      draw = !draw;
    }
  }

  return dashed;
}

List<TracePoint> getDigitReferenceSamples(int digit, int totalCount) {
  final segments = getDigitPathSegments(digit);
  final lengths = segments.map(_getSubpathLength).toList();
  final totalLength = lengths.fold<double>(0, (sum, length) => sum + length);

  if (totalLength == 0 || totalCount <= 0) {
    return const [];
  }

  final samples = <TracePoint>[];

  for (var index = 0; index < segments.length; index++) {
    final segment = segments[index];

    if (segment.length < 2) {
      continue;
    }

    final segmentCount =
        math.max(2, ((totalCount * lengths[index]) / totalLength).round());
    samples.addAll(_resamplePolyline(segment, segmentCount));
  }

  return samples;
}
