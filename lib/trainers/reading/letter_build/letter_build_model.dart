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
