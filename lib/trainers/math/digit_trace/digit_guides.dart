import 'dart:math' as math;

class TracePoint {
  const TracePoint({required this.x, required this.y});

  final double x;
  final double y;

  TracePoint copyWith({double? x, double? y}) {
    return TracePoint(x: x ?? this.x, y: y ?? this.y);
  }
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

final _guide0 = [_arc(0.5, 0.52, 0.24, 0, math.pi * 2, 36)];

final _guide1 = [
  _line(0.45, 0.28, 0.52, 0.2, 6),
  _line(0.52, 0.2, 0.52, 0.82, 24),
];

final _guide2 = [
  _arc(0.58, 0.3, 0.2, math.pi, math.pi * 2.15, 14),
  _line(0.38, 0.3, 0.72, 0.78, 14),
  _line(0.28, 0.78, 0.74, 0.78, 12),
];

final _guide3 = [
  _arc(0.52, 0.3, 0.2, math.pi * 0.85, math.pi * 2.2, 14),
  _arc(0.52, 0.58, 0.2, math.pi * 1.1, math.pi * 2.35, 14),
];

final _guide4 = [
  _line(0.62, 0.22, 0.34, 0.58, 14),
  _line(0.34, 0.58, 0.72, 0.58, 12),
  _line(0.62, 0.22, 0.62, 0.8, 16),
];

final _guide5 = [
  _line(0.68, 0.22, 0.32, 0.22, 10),
  _line(0.32, 0.22, 0.3, 0.46, 10),
  _arc(0.52, 0.46, 0.2, math.pi, math.pi * 2.05, 14),
  _line(0.72, 0.66, 0.3, 0.78, 12),
];

final _guide6 = [
  _arc(0.5, 0.58, 0.22, math.pi * 0.35, math.pi * 2.25, 22),
  _line(0.34, 0.42, 0.34, 0.28, 8),
  _arc(0.5, 0.28, 0.16, math.pi, math.pi * 2.05, 12),
];

final _guide7 = [
  _line(0.28, 0.22, 0.72, 0.22, 12),
  _line(0.72, 0.22, 0.48, 0.8, 16),
];

final _guide8 = [
  _arc(0.5, 0.34, 0.18, 0, math.pi * 2, 18),
  _arc(0.5, 0.64, 0.2, 0, math.pi * 2, 20),
];

final _guide9 = [
  _arc(0.5, 0.36, 0.18, 0, math.pi * 2, 18),
  _line(0.5, 0.54, 0.5, 0.8, 12),
  _line(0.36, 0.8, 0.64, 0.8, 10),
];

final _digitGuideSegments = <int, List<List<TracePoint>>>{
  0: _guide0,
  1: _guide1,
  2: _guide2,
  3: _guide3,
  4: _guide4,
  5: _guide5,
  6: _guide6,
  7: _guide7,
  8: _guide8,
  9: _guide9,
};

List<List<TracePoint>> getDigitGuideSegments(int digit) {
  return _digitGuideSegments[digit] ?? _guide0;
}

List<TracePoint> getDigitGuidePoints(int digit) {
  return getDigitGuideSegments(digit).expand((segment) => segment).toList();
}
