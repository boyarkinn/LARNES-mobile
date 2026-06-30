import 'dart:math' as math;

class DotPosition {
  const DotPosition({required this.x, required this.y});

  final double x;
  final double y;
}

const _dotPatterns = <int, List<DotPosition>>{
  0: [],
  1: [DotPosition(x: 0.5, y: 0.5)],
  2: [
    DotPosition(x: 0.32, y: 0.32),
    DotPosition(x: 0.68, y: 0.68),
  ],
  3: [
    DotPosition(x: 0.5, y: 0.24),
    DotPosition(x: 0.28, y: 0.72),
    DotPosition(x: 0.72, y: 0.72),
  ],
  4: [
    DotPosition(x: 0.3, y: 0.3),
    DotPosition(x: 0.7, y: 0.3),
    DotPosition(x: 0.3, y: 0.7),
    DotPosition(x: 0.7, y: 0.7),
  ],
  5: [
    DotPosition(x: 0.3, y: 0.3),
    DotPosition(x: 0.7, y: 0.3),
    DotPosition(x: 0.5, y: 0.5),
    DotPosition(x: 0.3, y: 0.7),
    DotPosition(x: 0.7, y: 0.7),
  ],
  6: [
    DotPosition(x: 0.3, y: 0.25),
    DotPosition(x: 0.7, y: 0.25),
    DotPosition(x: 0.3, y: 0.5),
    DotPosition(x: 0.7, y: 0.5),
    DotPosition(x: 0.3, y: 0.75),
    DotPosition(x: 0.7, y: 0.75),
  ],
  7: [
    DotPosition(x: 0.25, y: 0.25),
    DotPosition(x: 0.5, y: 0.25),
    DotPosition(x: 0.75, y: 0.25),
    DotPosition(x: 0.35, y: 0.5),
    DotPosition(x: 0.65, y: 0.5),
    DotPosition(x: 0.35, y: 0.75),
    DotPosition(x: 0.65, y: 0.75),
  ],
  8: [
    DotPosition(x: 0.25, y: 0.25),
    DotPosition(x: 0.5, y: 0.25),
    DotPosition(x: 0.75, y: 0.25),
    DotPosition(x: 0.25, y: 0.5),
    DotPosition(x: 0.75, y: 0.5),
    DotPosition(x: 0.25, y: 0.75),
    DotPosition(x: 0.5, y: 0.75),
    DotPosition(x: 0.75, y: 0.75),
  ],
  9: [
    DotPosition(x: 0.25, y: 0.22),
    DotPosition(x: 0.5, y: 0.22),
    DotPosition(x: 0.75, y: 0.22),
    DotPosition(x: 0.25, y: 0.5),
    DotPosition(x: 0.5, y: 0.5),
    DotPosition(x: 0.75, y: 0.5),
    DotPosition(x: 0.25, y: 0.78),
    DotPosition(x: 0.5, y: 0.78),
    DotPosition(x: 0.75, y: 0.78),
  ],
};

List<DotPosition> getPatternDotPositions(int count) {
  final safeCount = count.clamp(0, 9);
  return _dotPatterns[safeCount] ?? const [];
}

List<DotPosition> getGridDotPositions(int count) {
  if (count <= 0) {
    return const [];
  }

  final columns = math.sqrt(count).ceil();
  final rows = (count / columns).ceil();
  final positions = <DotPosition>[];

  for (var index = 0; index < count; index++) {
    final row = index ~/ columns;
    final column = index % columns;
    final itemsInRow = math.min(columns, count - row * columns);

    positions.add(
      DotPosition(
        x: (column + 0.5) / itemsInRow,
        y: (row + 0.5) / rows,
      ),
    );
  }

  return positions;
}

List<DotPosition> getDotPositionsForValue(int value) {
  final count = value < 0 ? 0 : value.truncate();
  if (count <= 9) {
    return getPatternDotPositions(count);
  }
  return getGridDotPositions(count);
}

double getDotRadius(int count) {
  if (count <= 9) {
    return 7;
  }
  if (count <= 20) {
    return 5;
  }
  if (count <= 50) {
    return 4;
  }
  return 3;
}
