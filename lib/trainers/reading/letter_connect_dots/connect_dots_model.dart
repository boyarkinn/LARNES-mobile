import 'dart:math' as math;
import 'dart:ui';

import 'package:larnes_mobile/trainers/math/digit_trace/digit_paths.dart';
import 'package:larnes_mobile/trainers/reading/letter_guides.dart';
import 'package:larnes_mobile/trainers/reading/letter_model.dart';

/// Web: `platform/src/trainers/reading/letter-connect-dots/model.ts`

const connectDotsViewboxSize = 100;
const connectDotsMergeEps = 0.022;
const connectDotsStraightDeviationMax = 0.012;
const connectDotsCurveSampleCount = 5;
const connectDotsDotSnapRadius = 9.0;
const connectDotsGuidePointEps = 0.018;
const connectDotsCoverageGapEps = 0.025;

class ConnectDot {
  const ConnectDot({
    required this.id,
    required this.number,
    required this.x,
    required this.y,
  });

  final String id;
  final int? number;
  final double x;
  final double y;
}

class ConnectEdge {
  const ConnectEdge({
    required this.aId,
    required this.bId,
    required this.orderIndex,
    required this.segmentIndex,
  });

  final String aId;
  final String bId;
  final int orderIndex;
  final int segmentIndex;
}

class ConnectGuideStroke {
  const ConnectGuideStroke({
    required this.id,
    required this.points,
  });

  final String id;
  final List<TracePoint> points;
}

class ConnectDotsPuzzle {
  const ConnectDotsPuzzle({
    required this.dots,
    required this.edges,
    required this.guideStrokes,
  });

  final List<ConnectDot> dots;
  final List<ConnectEdge> edges;
  final List<ConnectGuideStroke> guideStrokes;
}

class ConnectDrawnLine {
  const ConnectDrawnLine({
    required this.aId,
    required this.bId,
    required this.edgeKey,
    required this.onGuide,
  });

  final String aId;
  final String bId;
  final String edgeKey;
  final bool onGuide;
}

class ConnectShapeEvaluation {
  const ConnectShapeEvaluation({
    required this.isSuccess,
    required this.missingStrokeIds,
    required this.wrongLineKeys,
  });

  final bool isSuccess;
  final List<String> missingStrokeIds;
  final List<String> wrongLineKeys;
}

class ConnectPolylineProjection {
  const ConnectPolylineProjection({
    required this.distance,
    required this.t,
  });

  final double distance;
  final double t;
}

class AddConnectDrawnLineResult {
  const AddConnectDrawnLineResult({
    required this.line,
    required this.nextDrawnLines,
  });

  final ConnectDrawnLine? line;
  final List<ConnectDrawnLine> nextDrawnLines;
}

double _pointDistance(TracePoint a, TracePoint b) {
  return math.sqrt(math.pow(a.x - b.x, 2) + math.pow(a.y - b.y, 2));
}

double _pointToSegmentDistance(
  TracePoint point,
  TracePoint start,
  TracePoint end,
) {
  final dx = end.x - start.x;
  final dy = end.y - start.y;
  final lengthSquared = dx * dx + dy * dy;

  if (lengthSquared == 0) {
    return _pointDistance(point, start);
  }

  final t = ((point.x - start.x) * dx + (point.y - start.y) * dy) /
      lengthSquared;
  final clampedT = t.clamp(0.0, 1.0);

  return _pointDistance(
    point,
    TracePoint(
      x: start.x + clampedT * dx,
      y: start.y + clampedT * dy,
    ),
  );
}

int _findNearbyDotIndex(
  List<TracePoint> dots,
  TracePoint point, [
  double eps = connectDotsMergeEps,
]) {
  for (var index = 0; index < dots.length; index++) {
    if (_pointDistance(dots[index], point) <= eps) {
      return index;
    }
  }

  return -1;
}

List<TracePoint> _dedupeNearbyPoints(
  List<TracePoint> points, [
  double eps = connectDotsMergeEps,
]) {
  final result = <TracePoint>[];

  for (final point in points) {
    if (_findNearbyDotIndex(result, point, eps) < 0) {
      result.add(point);
    }
  }

  return result;
}

bool isNearlyStraightConnectSegment(List<TracePoint> segment) {
  if (segment.length <= 2) {
    return true;
  }

  final start = segment.first;
  final end = segment.last;

  return segment.every(
    (point) =>
        _pointToSegmentDistance(point, start, end) <=
        connectDotsStraightDeviationMax,
  );
}

List<TracePoint> sampleConnectSegmentPoints(List<TracePoint> segment) {
  if (segment.isEmpty) {
    return [];
  }

  if (segment.length == 1) {
    return [segment.first];
  }

  if (isNearlyStraightConnectSegment(segment)) {
    return [segment.first, segment.last];
  }

  final samples = <TracePoint>[];

  for (var index = 0; index < connectDotsCurveSampleCount; index++) {
    final pointIndex = ((index / (connectDotsCurveSampleCount - 1)) *
            (segment.length - 1))
        .round();
    samples.add(segment[pointIndex]);
  }

  return _dedupeNearbyPoints(samples);
}

String getConnectEdgeKey(String aId, String bId) {
  return aId.compareTo(bId) < 0 ? '$aId:$bId' : '$bId:$aId';
}

TracePoint? _getDotPoint(List<ConnectDot> dots, String dotId) {
  for (final dot in dots) {
    if (dot.id == dotId) {
      return TracePoint(x: dot.x, y: dot.y);
    }
  }

  return null;
}

ConnectPolylineProjection? projectPointToConnectPolyline(
  TracePoint point,
  List<TracePoint> polyline,
) {
  if (polyline.isEmpty) {
    return null;
  }

  if (polyline.length == 1) {
    return ConnectPolylineProjection(
      distance: _pointDistance(point, polyline.first),
      t: 0,
    );
  }

  var totalLength = 0.0;
  final segmentLengths = <double>[];

  for (var index = 0; index < polyline.length - 1; index++) {
    final length = _pointDistance(polyline[index], polyline[index + 1]);
    segmentLengths.add(length);
    totalLength += length;
  }

  var bestDistance = double.infinity;
  var bestT = 0.0;
  var accumulated = 0.0;

  for (var index = 0; index < polyline.length - 1; index++) {
    final start = polyline[index];
    final end = polyline[index + 1];
    final segmentLength = segmentLengths[index];

    if (segmentLength == 0) {
      continue;
    }

    final dx = end.x - start.x;
    final dy = end.y - start.y;
    final projectionT = (((point.x - start.x) * dx +
                (point.y - start.y) * dy) /
            (segmentLength * segmentLength))
        .clamp(0.0, 1.0);
    final projected = TracePoint(
      x: start.x + projectionT * dx,
      y: start.y + projectionT * dy,
    );
    final distance = _pointDistance(point, projected);
    final globalT = totalLength == 0
        ? 0.0
        : (accumulated + projectionT * segmentLength) / totalLength;

    if (distance < bestDistance) {
      bestDistance = distance;
      bestT = globalT;
    }

    accumulated += segmentLength;
  }

  return ConnectPolylineProjection(distance: bestDistance, t: bestT);
}

ConnectGuideStroke? findSharedConnectGuideStroke(
  List<ConnectGuideStroke> guideStrokes,
  TracePoint pointA,
  TracePoint pointB,
) {
  for (final stroke in guideStrokes) {
    final projectionA = projectPointToConnectPolyline(pointA, stroke.points);
    final projectionB = projectPointToConnectPolyline(pointB, stroke.points);

    if (projectionA != null &&
        projectionB != null &&
        projectionA.distance <= connectDotsGuidePointEps &&
        projectionB.distance <= connectDotsGuidePointEps) {
      return stroke;
    }
  }

  return null;
}

List<List<double>> _mergeCoverageIntervals(List<List<double>> intervals) {
  if (intervals.isEmpty) {
    return [];
  }

  final sorted = [...intervals]..sort((left, right) => left[0].compareTo(right[0]));
  final merged = <List<double>>[
    [sorted.first[0], sorted.first[1]],
  ];

  for (var index = 1; index < sorted.length; index++) {
    final current = sorted[index];
    final last = merged.last;

    if (current[0] <= last[1] + connectDotsCoverageGapEps) {
      last[1] = math.max(last[1], current[1]);
      continue;
    }

    merged.add([current[0], current[1]]);
  }

  return merged;
}

bool _isStrokeCovered(
  ConnectGuideStroke stroke,
  List<ConnectDot> dots,
  List<ConnectDrawnLine> drawnLines,
) {
  final intervals = <List<double>>[];

  for (final line in drawnLines) {
    final pointA = _getDotPoint(dots, line.aId);
    final pointB = _getDotPoint(dots, line.bId);

    if (pointA == null || pointB == null) {
      continue;
    }

    final sharedStroke = findSharedConnectGuideStroke([stroke], pointA, pointB);

    if (sharedStroke == null) {
      continue;
    }

    final projectionA = projectPointToConnectPolyline(pointA, stroke.points);
    final projectionB = projectPointToConnectPolyline(pointB, stroke.points);

    if (projectionA == null || projectionB == null) {
      continue;
    }

    intervals.add([
      math.min(projectionA.t, projectionB.t),
      math.max(projectionA.t, projectionB.t),
    ]);
  }

  final merged = _mergeCoverageIntervals(intervals);

  if (merged.isEmpty) {
    return false;
  }

  if (merged.first[0] > connectDotsCoverageGapEps) {
    return false;
  }

  if (merged.last[1] < 1 - connectDotsCoverageGapEps) {
    return false;
  }

  for (var index = 1; index < merged.length; index++) {
    if (merged[index][0] - merged[index - 1][1] > connectDotsCoverageGapEps) {
      return false;
    }
  }

  return true;
}

List<ConnectGuideStroke> buildConnectGuideStrokes(String letter) {
  final segments = getLetterGuideSegments(normalizeTargetLetter(letter));

  return [
    for (var index = 0; index < segments.length; index++)
      ConnectGuideStroke(
        id: 'guide-$index',
        points: segments[index],
      ),
  ];
}

ConnectDotsPuzzle buildLetterDotPuzzle(String letter) {
  final guideStrokes = buildConnectGuideStrokes(letter);
  final segments = guideStrokes.map((stroke) => stroke.points).toList();
  final dotPoints = <TracePoint>[];
  final dotIds = <String>[];
  final edges = <ConnectEdge>[];
  var orderIndex = 0;

  String getOrCreateDotId(TracePoint point) {
    final existingIndex = _findNearbyDotIndex(dotPoints, point);

    if (existingIndex >= 0) {
      return dotIds[existingIndex];
    }

    final id = 'dot-${dotPoints.length}';
    dotPoints.add(point);
    dotIds.add(id);
    return id;
  }

  for (var segmentIndex = 0; segmentIndex < segments.length; segmentIndex++) {
    final sampled = sampleConnectSegmentPoints(segments[segmentIndex]);

    for (var index = 1; index < sampled.length; index++) {
      final aId = getOrCreateDotId(sampled[index - 1]);
      final bId = getOrCreateDotId(sampled[index]);

      if (aId == bId) {
        continue;
      }

      final key = getConnectEdgeKey(aId, bId);

      if (edges.any((edge) => getConnectEdgeKey(edge.aId, edge.bId) == key)) {
        continue;
      }

      edges.add(
        ConnectEdge(
          aId: aId,
          bId: bId,
          orderIndex: orderIndex++,
          segmentIndex: segmentIndex,
        ),
      );
    }
  }

  final numberByDotId = <String, int>{};
  var nextNumber = 1;

  for (final edge in edges) {
    for (final dotId in [edge.aId, edge.bId]) {
      numberByDotId.putIfAbsent(dotId, () => nextNumber++);
    }
  }

  final dots = [
    for (var index = 0; index < dotPoints.length; index++)
      ConnectDot(
        id: dotIds[index],
        number: numberByDotId[dotIds[index]],
        x: dotPoints[index].x,
        y: dotPoints[index].y,
      ),
  ];

  return ConnectDotsPuzzle(
    dots: dots,
    edges: edges,
    guideStrokes: guideStrokes,
  );
}

ConnectDrawnLine? classifyConnectDrawnLine(
  ConnectDotsPuzzle puzzle,
  String aId,
  String bId,
) {
  if (aId == bId) {
    return null;
  }

  final pointA = _getDotPoint(puzzle.dots, aId);
  final pointB = _getDotPoint(puzzle.dots, bId);

  if (pointA == null || pointB == null) {
    return null;
  }

  final edgeKey = getConnectEdgeKey(aId, bId);
  final onGuide = findSharedConnectGuideStroke(
        puzzle.guideStrokes,
        pointA,
        pointB,
      ) !=
      null;

  return ConnectDrawnLine(
    aId: aId,
    bId: bId,
    edgeKey: edgeKey,
    onGuide: onGuide,
  );
}

AddConnectDrawnLineResult addConnectDrawnLine(
  ConnectDotsPuzzle puzzle,
  List<ConnectDrawnLine> drawnLines,
  String aId,
  String bId,
) {
  final line = classifyConnectDrawnLine(puzzle, aId, bId);

  if (line == null) {
    return AddConnectDrawnLineResult(
      line: null,
      nextDrawnLines: [...drawnLines],
    );
  }

  if (drawnLines.any((item) => item.edgeKey == line.edgeKey)) {
    return AddConnectDrawnLineResult(
      line: null,
      nextDrawnLines: [...drawnLines],
    );
  }

  return AddConnectDrawnLineResult(
    line: line,
    nextDrawnLines: [...drawnLines, line],
  );
}

List<ConnectDrawnLine> addConnectDrawnLinesFromPath(
  ConnectDotsPuzzle puzzle,
  List<ConnectDrawnLine> drawnLines,
  List<String> pathDotIds,
) {
  var nextDrawnLines = [...drawnLines];

  for (var index = 1; index < pathDotIds.length; index++) {
    final result = addConnectDrawnLine(
      puzzle,
      nextDrawnLines,
      pathDotIds[index - 1],
      pathDotIds[index],
    );
    nextDrawnLines = result.nextDrawnLines;
  }

  return nextDrawnLines;
}

ConnectShapeEvaluation evaluateConnectShapeCoverage(
  ConnectDotsPuzzle puzzle,
  List<ConnectDrawnLine> drawnLines,
) {
  final wrongLineKeys = drawnLines
      .where((line) => !line.onGuide)
      .map((line) => line.edgeKey)
      .toList();
  final missingStrokeIds = puzzle.guideStrokes
      .where((stroke) => !_isStrokeCovered(stroke, puzzle.dots, drawnLines))
      .map((stroke) => stroke.id)
      .toList();

  return ConnectShapeEvaluation(
    isSuccess: wrongLineKeys.isEmpty && missingStrokeIds.isEmpty,
    missingStrokeIds: missingStrokeIds,
    wrongLineKeys: wrongLineKeys,
  );
}

ConnectDot? findConnectDotAtViewboxPoint(
  List<ConnectDot> dots,
  double x,
  double y, {
  String? excludeDotId,
  double radius = connectDotsDotSnapRadius,
}) {
  ConnectDot? closest;
  var closestDistance = radius;

  for (final dot in dots) {
    if (dot.id == excludeDotId) {
      continue;
    }

    final dx = dot.x * connectDotsViewboxSize - x;
    final dy = dot.y * connectDotsViewboxSize - y;
    final distance = math.sqrt(dx * dx + dy * dy);

    if (distance <= closestDistance) {
      closest = dot;
      closestDistance = distance;
    }
  }

  return closest;
}

Offset connectDotToViewboxPoint(ConnectDot dot) {
  return Offset(
    dot.x * connectDotsViewboxSize,
    dot.y * connectDotsViewboxSize,
  );
}

Offset pointerToConnectViewboxPoint({
  required double localX,
  required double localY,
  required double padWidth,
  required double padHeight,
}) {
  return Offset(
    (localX / padWidth) * connectDotsViewboxSize,
    (localY / padHeight) * connectDotsViewboxSize,
  );
}
