import 'dart:ui';

import 'package:larnes_mobile/trainers/reading/letter_model.dart';
import 'package:larnes_mobile/trainers/shared/seeded_rng.dart';

/// Web: `platform/src/trainers/reading/letter-grid-match/model.ts`

const gridSizeValues = [2, 3];
const minFilledCount = 1;

class GridCell {
  const GridCell({
    required this.col,
    required this.id,
    required this.row,
  });

  final int col;
  final String id;
  final int row;
}

class GridPoolTile {
  const GridPoolTile({
    required this.id,
    required this.letter,
    required this.used,
  });

  final String id;
  final String letter;
  final bool used;

  GridPoolTile copyWith({
    String? id,
    String? letter,
    bool? used,
  }) {
    return GridPoolTile(
      id: id ?? this.id,
      letter: letter ?? this.letter,
      used: used ?? this.used,
    );
  }
}

class GridRound {
  const GridRound({
    required this.cells,
    required this.gridSize,
    required this.poolTiles,
    required this.reference,
  });

  final List<GridCell> cells;
  final int gridSize;
  final List<GridPoolTile> poolTiles;
  final Map<String, String?> reference;
}

int getCellCount(int gridSize) {
  return gridSize * gridSize;
}

int getMaxFilledCount(int gridSize) {
  return getCellCount(gridSize);
}

bool isValidGridSize(int value) {
  return gridSizeValues.contains(value);
}

bool isValidFilledCount(int gridSize, int filledCount) {
  return filledCount >= minFilledCount && filledCount <= getMaxFilledCount(gridSize);
}

List<GridCell> buildGridCells(int gridSize) {
  final cells = <GridCell>[];

  for (var row = 0; row < gridSize; row++) {
    for (var col = 0; col < gridSize; col++) {
      cells.add(
        GridCell(
          col: col,
          id: 'cell-$row-$col',
          row: row,
        ),
      );
    }
  }

  return cells;
}

List<T> _shuffleItems<T>(List<T> items, double Function() rng) {
  final next = [...items];

  for (var index = next.length - 1; index > 0; index--) {
    final swapIndex = (rng() * (index + 1)).floor();
    final temp = next[index];
    next[index] = next[swapIndex];
    next[swapIndex] = temp;
  }

  return next;
}

GridRound buildGridRound({
  required int filledCount,
  required int gridSize,
  required String letterCase,
  required List<String> practiceLetters,
  required int seed,
}) {
  final rng = createSeededRng(seed);
  final cells = buildGridCells(gridSize);
  final practicePool = [
    for (final letter in practiceLetters)
      applyLetterCase(letter, letterCase),
  ];
  final fallbackLetter =
      practicePool.isNotEmpty ? practicePool.first : applyLetterCase('А', letterCase);
  final shuffledCells = _shuffleItems(cells, rng);
  final filledCells = shuffledCells.take(filledCount).toList();
  final reference = <String, String?>{};

  for (final cell in cells) {
    reference[cell.id] = null;
  }

  final poolTiles = <GridPoolTile>[];

  for (var index = 0; index < filledCells.length; index++) {
    final cell = filledCells[index];
    final letterIndex = (rng() * practicePool.length).floor();
    final letter = practicePool.isNotEmpty
        ? practicePool[letterIndex]
        : fallbackLetter;
    reference[cell.id] = letter;
    poolTiles.add(
      GridPoolTile(
        id: 'tile-$index',
        letter: letter,
        used: false,
      ),
    );
  }

  return GridRound(
    cells: cells,
    gridSize: gridSize,
    poolTiles: _shuffleItems(poolTiles, rng),
    reference: reference,
  );
}

bool isGridMatch(
  Map<String, String?> reference,
  Map<String, String?> target,
) {
  for (final cellId in reference.keys) {
    if (reference[cellId] != target[cellId]) {
      return false;
    }
  }

  return true;
}

int buildRoundSeed(List<Object> parts) {
  return hashParamsSeed([...parts, 'letter-grid-match']);
}

bool isPointInsideRect(double x, double y, Rect rect) {
  return x >= rect.left &&
      x <= rect.right &&
      y >= rect.top &&
      y <= rect.bottom;
}

/// Re-export for trainer/scene parity with web imports from model.
List<String> parseGridMatchPracticeLetters(String raw) => parsePracticeLetters(raw);

String formatGridMatchPracticeLetters(List<String> letters) =>
    formatPracticeLetters(letters);
