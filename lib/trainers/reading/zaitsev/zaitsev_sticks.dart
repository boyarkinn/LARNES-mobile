import 'dart:math' as math;

import 'package:larnes_mobile/trainers/math/digit_trace/digit_paths.dart';
import 'package:larnes_mobile/trainers/reading/zaitsev/path_geometry.dart';
import 'package:larnes_mobile/trainers/reading/zaitsev/zaitsev_catalog.dart';
import 'package:larnes_mobile/trainers/reading/zaitsev/zaitsev_types.dart';

/// Web: `platform/src/trainers/reading/letter-build/zaitsev-sticks.ts`

class StickPieceDef {
  const StickPieceDef({
    required this.id,
    required this.path,
    required this.centroid,
    required this.size,
    required this.paletteOffset,
    required this.bounds,
  });

  final String id;
  final String path;
  final TracePoint centroid;
  final double size;
  final TracePoint paletteOffset;
  final PathBounds bounds;
}

class BuildLayout extends PathBounds {
  const BuildLayout({
    required super.minX, required super.minY,
    required super.maxX, required super.maxY,
    required this.padding,
  });

  final double padding;
}

class _PaletteColumn {
  var height = 0.0;
  var width = 0.0;
  final indices = <int>[];
}

final _buildPiecesCache = <String, List<StickPieceDef>>{};
final _buildLayoutCache = <String, BuildLayout>{};

void _ensureBuildCache() {
  if (_buildPiecesCache.isNotEmpty) {
    return;
  }

  for (final entry in zaitsevLetterDrawings.entries) {
    if (entry.value.strokes.isEmpty) {
      continue;
    }

    _buildPiecesCache[entry.key] = _buildPiecesFromDrawing(
      entry.key,
      entry.value,
    );
  }
}

List<StickPieceDef> _assignPaletteOffsets(
  List<StickPieceDef> pieces,
  String letter,
  ZaitsevLetterDrawing drawing,
) {
  final padding = drawing.strokeWidth / 2 + 8;
  const gap = 20.0;
  const sideGap = 36.0;
  final outline = PathBounds(
    minX: pieces.map((piece) => piece.bounds.minX).reduce(math.min) - padding,
    minY: pieces.map((piece) => piece.bounds.minY).reduce(math.min) - padding,
    maxX: pieces.map((piece) => piece.bounds.maxX).reduce(math.max) + padding,
    maxY: pieces.map((piece) => piece.bounds.maxY).reduce(math.max) + padding,
  );
  final columns = [_PaletteColumn(), _PaletteColumn()];
  final heights = [for (final piece in pieces) piece.bounds.height + padding * 2];
  final widths = [for (final piece in pieces) piece.bounds.width + padding * 2];
  final order = List<int>.generate(pieces.length, (index) => index)
    ..sort((a, b) {
      final byHeight = heights[b].compareTo(heights[a]);
      return byHeight == 0 ? a.compareTo(b) : byHeight;
    });
  for (final index in order) {
    final column = columns[0].height <= columns[1].height ? columns[0] : columns[1];
    column.height += (column.indices.isEmpty ? 0 : gap) + heights[index];
    column.width = math.max(column.width, widths[index]);
    column.indices.add(index);
  }
  final offsets = List<TracePoint>.filled(pieces.length, const TracePoint(x: 0, y: 0));
  var minX = outline.minX;
  var minY = outline.minY;
  var maxX = outline.maxX;
  var maxY = outline.maxY;
  for (var side = 0; side < columns.length; side++) {
    final column = columns[side];
    final centerX = side == 0
        ? outline.minX - sideGap - column.width / 2
        : outline.maxX + sideGap + column.width / 2;
    var top = (outline.minY + outline.maxY - column.height) / 2;
    for (final index in column.indices) {
      final piece = pieces[index];
      final centerY = top + heights[index] / 2;
      offsets[index] = TracePoint(
        x: (centerX - (piece.bounds.minX + piece.bounds.maxX) / 2) / zaitsevCoordSize,
        y: (centerY - (piece.bounds.minY + piece.bounds.maxY) / 2) / zaitsevCoordSize,
      );
      minX = math.min(minX, centerX - widths[index] / 2);
      maxX = math.max(maxX, centerX + widths[index] / 2);
      minY = math.min(minY, top);
      maxY = math.max(maxY, top + heights[index]);
      top += heights[index] + gap;
    }
  }
  const margin = 24.0;
  _buildLayoutCache[letter] = BuildLayout(
    minX: minX - margin, minY: minY - margin,
    maxX: maxX + margin, maxY: maxY + margin, padding: padding,
  );
  return [
    for (var index = 0; index < pieces.length; index++)
      StickPieceDef(
        id: pieces[index].id, path: pieces[index].path,
        centroid: pieces[index].centroid, size: pieces[index].size,
        bounds: pieces[index].bounds, paletteOffset: offsets[index],
      ),
  ];
}

List<StickPieceDef> _buildPiecesFromDrawing(
  String letter,
  ZaitsevLetterDrawing drawing,
) {
  final raw = [
    for (var index = 0; index < drawing.strokes.length; index++)
      StickPieceDef(
        id: '$letter-$index',
        bounds: getPathBounds(drawing.strokes[index].path),
        path: drawing.strokes[index].path,
        centroid: getPathCentroid(drawing.strokes[index].path),
        size: getPathCharacteristicSize(drawing.strokes[index].path),
        paletteOffset: const TracePoint(x: 0, y: 0),
      ),
  ];

  return _assignPaletteOffsets(raw, letter, drawing);
}

List<String> listSupportedBuildLetters() {
  _ensureBuildCache();

  final letters = _buildPiecesCache.keys.toList()
    ..sort((a, b) => a.compareTo(b));
  return letters;
}

bool isSupportedBuildLetter(String letter) {
  _ensureBuildCache();
  return _buildPiecesCache.containsKey(letter);
}

List<StickPieceDef> getLetterBuildPieces(String letter) {
  _ensureBuildCache();
  return _buildPiecesCache[letter] ?? const [];
}

ZaitsevLetterDrawing? getBuildDrawing(String letter) {
  final drawing = getZaitsevLetterDrawing(letter);

  if (drawing == null || drawing.strokes.isEmpty) {
    return null;
  }

  return drawing;
}

BuildLayout? getBuildLayout(String letter) {
  _ensureBuildCache();
  return _buildLayoutCache[letter];
}

void resetBuildPiecesCacheForTests() {
  _buildPiecesCache.clear();
  _buildLayoutCache.clear();
}
