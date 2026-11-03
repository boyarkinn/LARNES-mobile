import 'dart:math' as math;
import 'dart:ui';

const pairConnectionColor = Color(0xFF22C55E);

double pairCircleBorderWidth(double diameter) => diameter <= 0 ? 0.0 : math.min(3.0, math.max(1.0, (diameter * 0.05).roundToDouble()));

class PairCircleConnection {
  const PairCircleConnection({required this.from, required this.control1, required this.control2, required this.to});
  final Offset from, control1, control2, to;

  Path toPath() => Path()
    ..moveTo(from.dx, from.dy)
    ..cubicTo(control1.dx, control1.dy, control2.dx, control2.dy, to.dx, to.dy);
}

/// Same endpoints and control points as Web letter-pair-connect/connection-geometry.ts.
PairCircleConnection? buildPairCircleConnection(Offset first, Offset second, double radius) {
  final ordered = first.dx < second.dx || first.dx == second.dx && first.dy <= second.dy;
  final start = ordered ? first : second;
  final end = ordered ? second : first;
  final difference = end - start;
  final distance = difference.distance;
  if (radius < 0 || !distance.isFinite || !radius.isFinite || distance <= radius * 2) return null;
  final ux = difference.dx / distance, uy = difference.dy / distance;
  final from = start + Offset(ux * radius, uy * radius);
  final to = end - Offset(ux * radius, uy * radius);
  final gap = distance - radius * 2;
  final bend = math.min(math.max(28.0, (to.dx - from.dx).abs() * 0.38), ux > 0 ? gap * 0.38 / ux : double.infinity);
  return PairCircleConnection(from: from, control1: from + Offset(bend, 0), control2: to - Offset(bend, 0), to: to);
}
