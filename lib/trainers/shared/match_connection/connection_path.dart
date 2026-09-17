import 'dart:math' as math;
import 'dart:ui';

/// Web: `platform/src/trainers/shared/match-connection/connection-path.ts`
Path buildConnectionPath(Offset from, Offset to) {
  final bend = math.max(28.0, (to.dx - from.dx).abs() * 0.38);

  return Path()
    ..moveTo(from.dx, from.dy)
    ..cubicTo(from.dx + bend, from.dy, to.dx - bend, to.dy, to.dx, to.dy);
}

void drawDashedConnectionPath(Canvas canvas, Path path, Paint paint) {
  const dashWidth = 8.0;
  const dashSpace = 6.0;

  for (final metric in path.computeMetrics()) {
    var distance = 0.0;
    while (distance < metric.length) {
      final end = math.min(distance + dashWidth, metric.length);
      canvas.drawPath(metric.extractPath(distance, end), paint);
      distance += dashWidth + dashSpace;
    }
  }
}
