import 'dart:math';

class BoardPoint {
  const BoardPoint(this.x, this.y);

  final double x;
  final double y;
}

/// Слияние линий доски по версии. То же правило, что у доски в браузере.
List<Map<String, dynamic>> mergeBoardElements(
  List<Map<String, dynamic>> local,
  List<Map<String, dynamic>> remote,
) {
  final localById = <String, Map<String, dynamic>>{};
  final unkeyed = <Map<String, dynamic>>[];
  for (final element in local) {
    final id = _id(element);
    if (id.isEmpty) {
      unkeyed.add(element);
      continue;
    }
    localById[id] = element;
  }

  final seen = <String>{};
  final merged = <Map<String, dynamic>>[];
  for (final remoteElement in remote) {
    final id = _id(remoteElement);
    if (id.isEmpty || !seen.add(id)) {
      continue;
    }
    final localElement = localById[id];
    merged.add(localElement != null && _keepLocal(localElement, remoteElement) ? localElement : remoteElement);
  }
  for (final element in local) {
    final id = _id(element);
    if (id.isEmpty || !seen.add(id)) {
      continue;
    }
    merged.add(element);
  }
  merged.addAll(unkeyed);
  return merged;
}

List<Map<String, dynamic>> readBoardElements(Object? raw) {
  if (raw is! List) {
    return const [];
  }
  final elements = <Map<String, dynamic>>[];
  for (final item in raw) {
    if (item is Map<String, dynamic>) {
      elements.add(item);
    } else if (item is Map) {
      elements.add(Map<String, dynamic>.from(item));
    }
  }
  return elements;
}

Map<String, dynamic> freedrawElement(List<BoardPoint> points, String color, {int width = 2}) {
  final origin = points.first;
  final local = <List<double>>[];
  var maxX = 0.0;
  var maxY = 0.0;
  var minX = 0.0;
  var minY = 0.0;
  for (final point in points) {
    final x = point.x - origin.x;
    final y = point.y - origin.y;
    local.add([_round(x), _round(y)]);
    maxX = max(maxX, x);
    maxY = max(maxY, y);
    minX = min(minX, x);
    minY = min(minY, y);
  }
  final now = DateTime.now().millisecondsSinceEpoch;
  final random = Random();
  return {
    'id': _elementId(random),
    'type': 'freedraw',
    'x': _round(origin.x),
    'y': _round(origin.y),
    'width': _round(maxX - minX),
    'height': _round(maxY - minY),
    'angle': 0,
    'strokeColor': color,
    'backgroundColor': 'transparent',
    'fillStyle': 'solid',
    'strokeWidth': width,
    'strokeStyle': 'solid',
    'roughness': 0,
    'opacity': 100,
    'groupIds': <String>[],
    'frameId': null,
    'roundness': null,
    'seed': random.nextInt(1 << 31),
    'version': 1,
    'versionNonce': random.nextInt(1 << 31),
    'index': null,
    'isDeleted': false,
    'boundElements': null,
    'updated': now,
    'link': null,
    'locked': false,
    'points': local,
    'pressures': <double>[],
    'simulatePressure': true,
    'lastCommittedPoint': null,
  };
}

/// Помечает задетые линии удалёнными. Пустой результат значит, что стирать нечего.
List<Map<String, dynamic>>? eraseBoardElements(
  List<Map<String, dynamic>> elements,
  BoardPoint at,
  double radius,
) {
  var changed = false;
  final next = <Map<String, dynamic>>[];
  final now = DateTime.now().millisecondsSinceEpoch;
  final random = Random();
  for (final element in elements) {
    if (element['type'] == 'freedraw' && element['isDeleted'] != true && _hits(element, at, radius)) {
      changed = true;
      next.add({
        ...element,
        'isDeleted': true,
        'version': _version(element) + 1,
        'versionNonce': random.nextInt(1 << 31),
        'updated': now,
      });
      continue;
    }
    next.add(element);
  }
  if (!changed) {
    return null;
  }
  return next;
}

bool _keepLocal(Map<String, dynamic> local, Map<String, dynamic> remote) {
  final localVersion = _version(local);
  final remoteVersion = _version(remote);
  if (localVersion > remoteVersion) {
    return true;
  }
  return localVersion == remoteVersion && _nonce(local) < _nonce(remote);
}

bool _hits(Map<String, dynamic> element, BoardPoint at, double radius) {
  final originX = _number(element['x']);
  final originY = _number(element['y']);
  final raw = element['points'];
  if (raw is! List || raw.isEmpty) {
    return false;
  }
  final points = <BoardPoint>[];
  for (final point in raw) {
    if (point is! List || point.length < 2) {
      continue;
    }
    points.add(BoardPoint(originX + _number(point[0]), originY + _number(point[1])));
  }
  if (points.isEmpty) {
    return false;
  }
  final limit = radius * radius;
  if (points.length == 1) {
    final deltaX = points.first.x - at.x;
    final deltaY = points.first.y - at.y;
    return deltaX * deltaX + deltaY * deltaY <= limit;
  }
  for (var index = 1; index < points.length; index += 1) {
    if (_segmentDistance2(points[index - 1], points[index], at) <= limit) {
      return true;
    }
  }
  return false;
}

double _segmentDistance2(BoardPoint start, BoardPoint end, BoardPoint at) {
  final dx = end.x - start.x;
  final dy = end.y - start.y;
  final length = dx * dx + dy * dy;
  if (length == 0) {
    final deltaX = at.x - start.x;
    final deltaY = at.y - start.y;
    return deltaX * deltaX + deltaY * deltaY;
  }
  final t = (((at.x - start.x) * dx + (at.y - start.y) * dy) / length).clamp(0.0, 1.0);
  final deltaX = at.x - (start.x + dx * t);
  final deltaY = at.y - (start.y + dy * t);
  return deltaX * deltaX + deltaY * deltaY;
}

String _id(Map<String, dynamic> element) {
  final id = element['id'];
  return id is String ? id : '';
}

int _version(Map<String, dynamic> element) {
  final version = element['version'];
  return version is num ? version.toInt() : 0;
}

int _nonce(Map<String, dynamic> element) {
  final nonce = element['versionNonce'];
  return nonce is num ? nonce.toInt() : 0;
}

double _number(Object? value) => value is num ? value.toDouble() : 0;

double _round(double value) => (value * 100).round() / 100;

String _elementId(Random random) {
  const alphabet = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
  return List.generate(20, (_) => alphabet[random.nextInt(alphabet.length)]).join();
}
