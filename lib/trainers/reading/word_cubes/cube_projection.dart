import 'dart:math' as math;
import 'dart:ui';

// Same solid, camera and quarter-turn geometry as Web cube-projection.ts.
const wordCubeTurnMs = 420;
class _Vector {
  const _Vector(this.x, this.y, this.z);
  final double x, y, z;
}
class _Plane {
  const _Plane(this.normal, this.corners);
  final _Vector normal;
  final List<_Vector> corners;
}
const _planes = [
  _Plane(_Vector(0, 0, 1), [_Vector(-1, 1, 1), _Vector(1, 1, 1), _Vector(1, -1, 1), _Vector(-1, -1, 1)]),
  _Plane(_Vector(1, 0, 0), [_Vector(1, 1, 1), _Vector(1, 1, -1), _Vector(1, -1, -1), _Vector(1, -1, 1)]),
  _Plane(_Vector(0, 0, -1), [_Vector(1, 1, -1), _Vector(-1, 1, -1), _Vector(-1, -1, -1), _Vector(1, -1, -1)]),
  _Plane(_Vector(-1, 0, 0), [_Vector(-1, 1, -1), _Vector(-1, 1, 1), _Vector(-1, -1, 1), _Vector(-1, -1, -1)]),
  _Plane(_Vector(0, 1, 0), [_Vector(-1, 1, -1), _Vector(1, 1, -1), _Vector(1, 1, 1), _Vector(-1, 1, 1)]),
  _Plane(_Vector(0, -1, 0), [_Vector(-1, -1, 1), _Vector(1, -1, 1), _Vector(1, -1, -1), _Vector(-1, -1, -1)]),
];
class CubeSurface {
  const CubeSurface(this.id, this.points, this.light, this.depth, this.textMatrix);
  final int id;
  final List<Offset> points;
  final double light, depth;
  final List<double> textMatrix;
}
class ProjectedWordCube {
  const ProjectedWordCube(this.surfaces, this.silhouette, this.outline);
  final List<CubeSurface> surfaces;
  final List<Offset> silhouette;
  final Path outline;
}
double _cross(Offset a, Offset b, Offset c) => (b.dx - a.dx) * (c.dy - a.dy) - (b.dy - a.dy) * (c.dx - a.dx);
List<Offset> _hull(List<Offset> points) {
  final sorted = [...points]..sort((a, b) => a.dx != b.dx ? a.dx.compareTo(b.dx) : a.dy.compareTo(b.dy));
  List<Offset> half(List<Offset> values) {
    final result = <Offset>[];
    for (final point in values) {
      while (result.length > 1 && _cross(result[result.length - 2], result.last, point) <= 0) { result.removeLast(); }
      result.add(point);
    }
    result.removeLast(); return result;
  }
  return [...half(sorted), ...half(sorted.reversed.toList())];
}
Path cubePolygonPath(List<Offset> points, {double radius = 0}) {
  final path = Path();
  if (radius == 0) {
    path.moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) { path.lineTo(point.dx, point.dy); }
    return path..close();
  }
  final enter = <Offset>[], leave = <Offset>[];
  for (var i = 0; i < points.length; i++) {
    final point = points[i], before = points[(i + points.length - 1) % points.length], after = points[(i + 1) % points.length];
    final a = (before - point).distance, b = (after - point).distance;
    final r = math.min(radius, math.min(a * 0.22, b * 0.22));
    enter.add(point + (before - point) * (r / a)); leave.add(point + (after - point) * (r / b));
  }
  path.moveTo(leave.last.dx, leave.last.dy);
  for (var i = 0; i < points.length; i++) {
    path.lineTo(enter[i].dx, enter[i].dy);
    path.quadraticBezierTo(points[i].dx, points[i].dy, leave[i].dx, leave[i].dy);
  }
  return path..close();
}
ProjectedWordCube projectWordCube(double quarterTurns) {
  final yaw = (-18 - quarterTurns * 90) * math.pi / 180, pitch = 12 * math.pi / 180;
  _Vector rotate(_Vector point) {
    final x = point.x * math.cos(yaw) + point.z * math.sin(yaw);
    final z = -point.x * math.sin(yaw) + point.z * math.cos(yaw);
    return _Vector(x, point.y * math.cos(pitch) - z * math.sin(pitch), point.y * math.sin(pitch) + z * math.cos(pitch));
  }
  Offset project(_Vector point) => Offset(56 + point.x * 272 / (8 - point.z), 54 - point.y * 272 / (8 - point.z));
  final all = <Offset>[for (final x in [-1.0, 1.0]) for (final y in [-1.0, 1.0]) for (final z in [-1.0, 1.0]) project(rotate(_Vector(x, y, z)))];
  final surfaces = <CubeSurface>[];
  for (var i = 0; i < _planes.length; i++) {
    final plane = _planes[i], normal = rotate(_planes[i].normal);
    if (normal.z * 8 <= 1.00001) continue;
    final rotated = plane.corners.map(rotate).toList(), points = rotated.map(project).toList();
    final a = points[0], b = points[1], d = points[3];
    surfaces.add(CubeSurface(i, points, ((normal.z - 0.1) / 0.9).clamp(0.0, 1.0).toDouble(), rotated.fold<double>(0, (sum, point) => sum + point.z) / 4,
      [(b.dx - a.dx) / 100, (b.dy - a.dy) / 100, (d.dx - a.dx) / 100, (d.dy - a.dy) / 100, a.dx, a.dy]));
  }
  surfaces.sort((a, b) => a.depth.compareTo(b.depth));
  final silhouette = _hull(all);
  return ProjectedWordCube(surfaces, silhouette, cubePolygonPath(silhouette, radius: 8));
}
String cubeSideText(List<String> faces, String current, int side, int completedTurns, bool turning) {
  final offset = (side - completedTurns % 4 + 4) % 4;
  if (side > 3 || (offset != 0 && !(turning && offset == 1))) return '';
  return faces[(faces.indexOf(current) + offset) % faces.length];
}
