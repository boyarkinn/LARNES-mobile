import 'dart:math' as math;
import 'dart:ui';

import 'package:larnes_mobile/trainers/math/digit_trace/digit_paths.dart';

/// Web: `platform/src/trainers/reading/letter-build/path-geometry.ts`

const zaitsevCoordSize = 350.0;

TracePoint normalizeZaitsevPoint(double x, double y) {
  return TracePoint(
    x: x / zaitsevCoordSize,
    y: y / zaitsevCoordSize,
  );
}

class _SvgCommand {
  const _SvgCommand(this.type, this.args);

  final String type;
  final List<double> args;
}

List<_SvgCommand> _tokenizeSvgPath(String path) {
  final commands = <_SvgCommand>[];
  final re = RegExp(
    r'([MLAQZ])|([+-]?(?:\d*\.\d+|\d+)(?:e[+-]?\d+)?)',
    caseSensitive: false,
  );
  final tokens = <Object>[];

  for (final match in re.allMatches(path)) {
    if (match.group(1) != null) {
      tokens.add(match.group(1)!.toUpperCase());
    } else if (match.group(2) != null) {
      tokens.add(double.parse(match.group(2)!));
    }
  }

  var index = 0;

  while (index < tokens.length) {
    final type = tokens[index];

    if (type is! String) {
      index += 1;
      continue;
    }

    index += 1;
    final args = <double>[];

    while (index < tokens.length && tokens[index] is num) {
      args.add((tokens[index] as num).toDouble());
      index += 1;
    }

    commands.add(_SvgCommand(type, args));
  }

  return commands;
}

double _lerp(double a, double b, double t) {
  return a + (b - a) * t;
}

void _sampleLine(
  double x1,
  double y1,
  double x2,
  double y2,
  int steps,
  List<TracePoint> out,
) {
  for (var step = 0; step <= steps; step++) {
    final t = step / steps;
    out.add(normalizeZaitsevPoint(_lerp(x1, x2, t), _lerp(y1, y2, t)));
  }
}

void _sampleQuadratic(
  double x1,
  double y1,
  double cx,
  double cy,
  double x2,
  double y2,
  int steps,
  List<TracePoint> out,
) {
  for (var step = 0; step <= steps; step++) {
    final t = step / steps;
    final u = 1 - t;
    final x = u * u * x1 + 2 * u * t * cx + t * t * x2;
    final y = u * u * y1 + 2 * u * t * cy + t * t * y2;
    out.add(normalizeZaitsevPoint(x, y));
  }
}

void _sampleArc(
  double x1,
  double y1,
  double rx,
  double ry,
  double xAxisRotation,
  int largeArcFlag,
  int sweepFlag,
  double x2,
  double y2,
  int steps,
  List<TracePoint> out,
) {
  if (rx == 0 || ry == 0) {
    _sampleLine(x1, y1, x2, y2, steps, out);
    return;
  }

  final phi = xAxisRotation * math.pi / 180;
  final cosPhi = math.cos(phi);
  final sinPhi = math.sin(phi);

  final dx = (x1 - x2) / 2;
  final dy = (y1 - y2) / 2;
  final x1p = cosPhi * dx + sinPhi * dy;
  final y1p = -sinPhi * dx + cosPhi * dy;

  var rxSq = rx * rx;
  var rySq = ry * ry;
  final x1pSq = x1p * x1p;
  final y1pSq = y1p * y1p;

  final lambda = x1pSq / rxSq + y1pSq / rySq;

  if (lambda > 1) {
    final scale = math.sqrt(lambda);
    rx *= scale;
    ry *= scale;
    rxSq = rx * rx;
    rySq = ry * ry;
  }

  final sign = largeArcFlag == sweepFlag ? -1 : 1;
  final numerator = rxSq * rySq - rxSq * y1pSq - rySq * x1pSq;
  final denominator = rxSq * y1pSq + rySq * x1pSq;
  final coef = denominator == 0
      ? 0.0
      : sign * math.sqrt(math.max(0, numerator / denominator));
  final cxp = (coef * rx * y1p) / ry;
  final cyp = (-coef * ry * x1p) / rx;

  final cx = cosPhi * cxp - sinPhi * cyp + (x1 + x2) / 2;
  final cy = sinPhi * cxp + cosPhi * cyp + (y1 + y2) / 2;

  double angleBetween(double ux, double uy, double vx, double vy) {
    final dot = ux * vx + uy * vy;
    final det = ux * vy - uy * vx;
    return math.atan2(det, dot);
  }

  final theta1 = angleBetween(1, 0, (x1p - cxp) / rx, (y1p - cyp) / ry);
  var delta = angleBetween(
    (x1p - cxp) / rx,
    (y1p - cyp) / ry,
    (-x1p - cxp) / rx,
    (-y1p - cyp) / ry,
  );

  if (sweepFlag == 0 && delta > 0) {
    delta -= 2 * math.pi;
  } else if (sweepFlag == 1 && delta < 0) {
    delta += 2 * math.pi;
  }

  for (var step = 0; step <= steps; step++) {
    final t = step / steps;
    final angle = theta1 + delta * t;
    final x = cx + rx * math.cos(angle) * cosPhi - ry * math.sin(angle) * sinPhi;
    final y = cy + rx * math.cos(angle) * sinPhi + ry * math.sin(angle) * cosPhi;
    out.add(normalizeZaitsevPoint(x, y));
  }
}

List<TracePoint> sampleSvgPath(String path, {int curveSteps = 14}) {
  final commands = _tokenizeSvgPath(path);
  final points = <TracePoint>[];
  var x = 0.0;
  var y = 0.0;
  var startX = 0.0;
  var startY = 0.0;

  for (final command in commands) {
    switch (command.type) {
      case 'M':
        x = command.args.isNotEmpty ? command.args[0] : x;
        y = command.args.length > 1 ? command.args[1] : y;
        startX = x;
        startY = y;
        points.add(normalizeZaitsevPoint(x, y));
      case 'L':
        final nextX = command.args.isNotEmpty ? command.args[0] : x;
        final nextY = command.args.length > 1 ? command.args[1] : y;
        _sampleLine(x, y, nextX, nextY, curveSteps, points);
        x = nextX;
        y = nextY;
      case 'Q':
        final cx = command.args.isNotEmpty ? command.args[0] : x;
        final cy = command.args.length > 1 ? command.args[1] : y;
        final nextX = command.args.length > 2 ? command.args[2] : x;
        final nextY = command.args.length > 3 ? command.args[3] : y;
        _sampleQuadratic(x, y, cx, cy, nextX, nextY, curveSteps, points);
        x = nextX;
        y = nextY;
      case 'A':
        final rx = command.args.isNotEmpty ? command.args[0].toDouble() : 0.0;
        final ry = command.args.length > 1 ? command.args[1].toDouble() : 0.0;
        final rotation =
            command.args.length > 2 ? command.args[2].toDouble() : 0.0;
        final largeArc = command.args.length > 3 ? command.args[3].round() : 0;
        final sweep = command.args.length > 4 ? command.args[4].round() : 0;
        final nextX =
            command.args.length > 5 ? command.args[5].toDouble() : x;
        final nextY =
            command.args.length > 6 ? command.args[6].toDouble() : y;
        _sampleArc(
          x,
          y,
          rx,
          ry,
          rotation,
          largeArc,
          sweep,
          nextX,
          nextY,
          curveSteps,
          points,
        );
        x = nextX;
        y = nextY;
      case 'Z':
        _sampleLine(x, y, startX, startY, curveSteps, points);
        x = startX;
        y = startY;
    }
  }

  return points;
}

TracePoint getPathCentroid(String path) {
  final points = sampleSvgPath(path);

  if (points.isEmpty) {
    return const TracePoint(x: 0.5, y: 0.5);
  }

  var sumX = 0.0;
  var sumY = 0.0;

  for (final point in points) {
    sumX += point.x;
    sumY += point.y;
  }

  return TracePoint(
    x: sumX / points.length,
    y: sumY / points.length,
  );
}

double getPathCharacteristicSize(String path) {
  final points = sampleSvgPath(path);

  if (points.isEmpty) {
    return 0.2;
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

  return math.max(math.max(maxX - minX, maxY - minY), 0.08);
}

String offsetToSvgTranslate(TracePoint offset) {
  return 'translate(${offset.x * zaitsevCoordSize} ${offset.y * zaitsevCoordSize})';
}

double parseZaitsevViewBoxSize(String viewBox) {
  final parts = viewBox.trim().split(RegExp(r'\s+'));

  if (parts.length >= 4) {
    return double.tryParse(parts[2]) ?? zaitsevCoordSize;
  }

  return zaitsevCoordSize;
}

Path buildZaitsevSvgPath(String path, {int curveSteps = 14}) {
  final commands = _tokenizeSvgPath(path);
  final flutterPath = Path();
  var x = 0.0;
  var y = 0.0;
  var startX = 0.0;
  var startY = 0.0;

  void addSampledPoints(List<TracePoint> points) {
    if (points.isEmpty) {
      return;
    }

    for (var index = 0; index < points.length; index++) {
      final point = points[index];
      final px = point.x * zaitsevCoordSize;
      final py = point.y * zaitsevCoordSize;

      if (index == 0 && flutterPath.getBounds().isEmpty) {
        flutterPath.moveTo(px, py);
      } else {
        flutterPath.lineTo(px, py);
      }
    }
  }

  for (final command in commands) {
    switch (command.type) {
      case 'M':
        x = command.args.isNotEmpty ? command.args[0] : x;
        y = command.args.length > 1 ? command.args[1] : y;
        startX = x;
        startY = y;
        flutterPath.moveTo(x, y);
      case 'L':
        final nextX = command.args.isNotEmpty ? command.args[0] : x;
        final nextY = command.args.length > 1 ? command.args[1] : y;
        flutterPath.lineTo(nextX, nextY);
        x = nextX;
        y = nextY;
      case 'Q':
        final cx = command.args.isNotEmpty ? command.args[0] : x;
        final cy = command.args.length > 1 ? command.args[1] : y;
        final nextX = command.args.length > 2 ? command.args[2] : x;
        final nextY = command.args.length > 3 ? command.args[3] : y;
        final sampled = <TracePoint>[];
        _sampleQuadratic(x, y, cx, cy, nextX, nextY, curveSteps, sampled);
        addSampledPoints(sampled);
        x = nextX;
        y = nextY;
      case 'A':
        final rx = command.args.isNotEmpty ? command.args[0].toDouble() : 0.0;
        final ry = command.args.length > 1 ? command.args[1].toDouble() : 0.0;
        final rotation =
            command.args.length > 2 ? command.args[2].toDouble() : 0.0;
        final largeArc = command.args.length > 3 ? command.args[3].round() : 0;
        final sweep = command.args.length > 4 ? command.args[4].round() : 0;
        final nextX =
            command.args.length > 5 ? command.args[5].toDouble() : x;
        final nextY =
            command.args.length > 6 ? command.args[6].toDouble() : y;
        final sampled = <TracePoint>[];
        _sampleArc(
          x,
          y,
          rx,
          ry,
          rotation,
          largeArc,
          sweep,
          nextX,
          nextY,
          curveSteps,
          sampled,
        );
        addSampledPoints(sampled);
        x = nextX;
        y = nextY;
      case 'Z':
        flutterPath.close();
        x = startX;
        y = startY;
    }
  }

  return flutterPath;
}

double distancePoint(TracePoint a, TracePoint b) {
  final dx = a.x - b.x;
  final dy = a.y - b.y;
  return math.sqrt(dx * dx + dy * dy);
}

final straightStrokePathPattern = RegExp(
  r'^M\s+([\d.]+)\s+([\d.]+)\s+L\s+([\d.]+)\s+([\d.]+)\s*$',
);

StraightStrokePath? parseStraightStrokePath(String path) {
  final match = straightStrokePathPattern.firstMatch(path);

  if (match == null) {
    return null;
  }

  return StraightStrokePath(
    a: normalizeZaitsevPoint(
      double.parse(match.group(1)!),
      double.parse(match.group(2)!),
    ),
    b: normalizeZaitsevPoint(
      double.parse(match.group(3)!),
      double.parse(match.group(4)!),
    ),
  );
}

class StraightStrokePath {
  const StraightStrokePath({
    required this.a,
    required this.b,
  });

  final TracePoint a;
  final TracePoint b;
}
