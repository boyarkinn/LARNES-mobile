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
  });

  final String id;
  final String path;
  final TracePoint centroid;
  final double size;
  final TracePoint paletteOffset;
}

final _buildPiecesCache = <String, List<StickPieceDef>>{};

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
) {
  final count = pieces.length;

  return [
    for (var index = 0; index < pieces.length; index++)
      () {
        final piece = pieces[index];
        final slotX = count == 1 ? 0.5 : 0.12 + (index / (count - 1)) * 0.76;
        final slotY = count <= 3
            ? 0.93
            : index < (count / 2).ceil()
                ? 0.9
                : 0.97;
        final paletteCentroid = TracePoint(x: slotX, y: slotY);

        return StickPieceDef(
          id: piece.id,
          path: piece.path,
          centroid: piece.centroid,
          size: piece.size,
          paletteOffset: TracePoint(
            x: paletteCentroid.x - piece.centroid.x,
            y: paletteCentroid.y - piece.centroid.y,
          ),
        );
      }(),
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
        path: drawing.strokes[index].path,
        centroid: getPathCentroid(drawing.strokes[index].path),
        size: getPathCharacteristicSize(drawing.strokes[index].path),
        paletteOffset: const TracePoint(x: 0, y: 0),
      ),
  ];

  return _assignPaletteOffsets(raw);
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

void resetBuildPiecesCacheForTests() {
  _buildPiecesCache.clear();
}
