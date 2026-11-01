import 'dart:math' as math;

import 'package:larnes_mobile/trainers/math/digit_trace/digit_paths.dart';
import 'package:larnes_mobile/trainers/math/digit_trace/trace_feedback.dart';
import 'package:larnes_mobile/trainers/reading/zaitsev/path_geometry.dart';
import 'package:larnes_mobile/trainers/reading/zaitsev/zaitsev_sticks.dart';

/// Web: `platform/src/trainers/reading/letter-build/model.ts`

enum BuildPhase { guide, free }

const buildPassPercent = tracePassPercent;
const snapOffsetThreshold = 0.07;
const stickScoreTolerance = 0.35;

class PiecePlacement {
  const PiecePlacement({
    required this.id,
    required this.offset,
    required this.snapped,
  });

  final String id;
  final TracePoint offset;
  final bool snapped;

  PiecePlacement copyWith({
    TracePoint? offset,
    bool? snapped,
  }) {
    return PiecePlacement(
      id: id,
      offset: offset ?? this.offset,
      snapped: snapped ?? this.snapped,
    );
  }
}

class BuildScore {
  const BuildScore({
    required this.hasEnoughInk,
    required this.similarityPercent,
    required this.strokeLength,
  });

  final bool hasEnoughInk;
  final int? similarityPercent;
  final double strokeLength;
}

List<PiecePlacement> createInitialPlacements(List<StickPieceDef> pieces) {
  return [
    for (final piece in pieces)
      PiecePlacement(
        id: piece.id,
        offset: TracePoint(
          x: piece.paletteOffset.x,
          y: piece.paletteOffset.y,
        ),
        snapped: false,
      ),
  ];
}

bool canSnapPiece(StickPieceDef piece, PiecePlacement placement) {
  return distancePoint(placement.offset, const TracePoint(x: 0, y: 0)) <=
      snapOffsetThreshold;
}

PiecePlacement snapPiece(
  StickPieceDef piece,
  PiecePlacement placement,
) {
  return placement.copyWith(
    offset: const TracePoint(x: 0, y: 0),
    snapped: true,
  );
}

class _PieceShape {
  const _PieceShape(this.center, this.points);

  final TracePoint center;
  final List<TracePoint> points;
}

final _pieceShapes = Expando<_PieceShape>();
const _shapeTolerance = 0.000001;

_PieceShape _pieceShape(StickPieceDef piece) {
  final cached = _pieceShapes[piece];
  if (cached != null) return cached;

  final points = sampleSvgPath(piece.path);
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
  final center = points.isEmpty
      ? piece.centroid
      : TracePoint(x: (minX + maxX) / 2, y: (minY + maxY) / 2);
  final shape = _PieceShape(center, [
    for (final point in points)
      TracePoint(x: point.x - center.x, y: point.y - center.y),
  ]);
  _pieceShapes[piece] = shape;
  return shape;
}

bool areBuildPiecesInterchangeable(StickPieceDef a, StickPieceDef b) {
  if (a.id == b.id) return true;
  final first = _pieceShape(a).points;
  final second = _pieceShape(b).points;
  return first.isNotEmpty &&
      second.isNotEmpty &&
      first.every((point) => second.any(
          (other) => distancePoint(point, other) <= _shapeTolerance)) &&
      second.every((point) => first.any(
          (other) => distancePoint(point, other) <= _shapeTolerance));
}

List<PiecePlacement> snapBuildPiece(
  List<StickPieceDef> pieces,
  List<PiecePlacement> placements,
  String pieceId,
) {
  final pieceIndex = pieces.indexWhere((item) => item.id == pieceId);
  final placementIndex = placements.indexWhere((item) => item.id == pieceId);
  if (pieceIndex < 0 || placementIndex < 0) return placements;
  final piece = pieces[pieceIndex];
  final placement = placements[placementIndex];
  if (placement.snapped) return placements;

  final center = _pieceShape(piece).center;
  StickPieceDef? bestPiece;
  PiecePlacement? bestPlacement;
  TracePoint? bestOffset;
  var closest = snapOffsetThreshold;
  for (final target in pieces) {
    final index = placements.indexWhere((item) => item.id == target.id);
    if (index < 0 || placements[index].snapped ||
        !areBuildPiecesInterchangeable(piece, target)) {
      continue;
    }
    final targetCenter = _pieceShape(target).center;
    final offset = TracePoint(
      x: targetCenter.x - center.x,
      y: targetCenter.y - center.y,
    );
    final error = distancePoint(placement.offset, offset);
    if (error <= closest) {
      closest = error;
      bestPiece = target;
      bestPlacement = placements[index];
      bestOffset = offset;
    }
  }
  final target = bestPiece;
  final targetPlacement = bestPlacement;
  final offset = bestOffset;
  if (target == null || targetPlacement == null || offset == null) {
    return placements;
  }

  // IDs describe filled contour slots; identical remaining pieces keep their
  // visible positions when the dragged piece is assigned to another slot.
  return [
    for (final item in placements)
      if (item.id == target.id)
        snapPiece(target, item)
      else if (item.id == pieceId)
        item.copyWith(offset: TracePoint(
          x: targetPlacement.offset.x + offset.x,
          y: targetPlacement.offset.y + offset.y,
        ))
      else
        item,
  ];
}

bool isGuidePhaseComplete(
  List<StickPieceDef> pieces,
  List<PiecePlacement> placements,
) {
  return pieces.isNotEmpty && placements.every((placement) => placement.snapped);
}

double _scoreStickPlacement(StickPieceDef piece, PiecePlacement placement) {
  final offsetError = distancePoint(
    placement.offset,
    const TracePoint(x: 0, y: 0),
  );
  final normalizedError = offsetError / math.max(piece.size, 0.08);

  return math.max(0, 1 - normalizedError / stickScoreTolerance);
}

BuildScore scoreBuildPlacements(
  String letter,
  List<PiecePlacement> placements,
) {
  final pieces = getLetterBuildPieces(letter);

  if (pieces.isEmpty) {
    return const BuildScore(
      hasEnoughInk: false,
      similarityPercent: null,
      strokeLength: 0,
    );
  }

  final scores = [
    for (final piece in pieces)
      () {
        PiecePlacement? placement;
        for (final item in placements) {
          if (item.id == piece.id) {
            placement = item;
            break;
          }
        }

        if (placement == null) {
          return 0.0;
        }

        return _scoreStickPlacement(piece, placement);
      }(),
  ];

  final averageScore =
      scores.fold<double>(0, (sum, score) => sum + score) / scores.length;
  final strokeLength = pieces.fold<double>(0, (sum, piece) => sum + piece.size);

  return BuildScore(
    hasEnoughInk: true,
    similarityPercent: (averageScore * 100).round(),
    strokeLength: strokeLength,
  );
}

PiecePlacement translatePlacement(
  PiecePlacement placement,
  double deltaX,
  double deltaY,
) {
  return placement.copyWith(
    offset: TracePoint(
      x: placement.offset.x + deltaX,
      y: placement.offset.y + deltaY,
    ),
    snapped: false,
  );
}

List<StickPieceDef> getPiecesForLetter(String letter) {
  return getLetterBuildPieces(letter);
}

PiecePlacement constrainBuildPlacement(
  StickPieceDef piece, PiecePlacement placement, BuildLayout layout,
) {
  final minX = (layout.minX + layout.padding - piece.bounds.minX) / zaitsevCoordSize;
  final maxX = (layout.maxX - layout.padding - piece.bounds.maxX) / zaitsevCoordSize;
  final minY = (layout.minY + layout.padding - piece.bounds.minY) / zaitsevCoordSize;
  final maxY = (layout.maxY - layout.padding - piece.bounds.maxY) / zaitsevCoordSize;
  final x = placement.offset.x.clamp(minX, maxX).toDouble();
  final y = placement.offset.y.clamp(minY, maxY).toDouble();
  return x == placement.offset.x && y == placement.offset.y
      ? placement : placement.copyWith(offset: TracePoint(x: x, y: y));
}
