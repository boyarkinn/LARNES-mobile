import 'dart:math' as math;

/// Web v2: `platform/src/trainers/math/apple-count-show/geometry.ts`

class ScenePoint {
  const ScenePoint({required this.x, required this.y});

  final double x;
  final double y;
}

class AppleSceneLayout {
  const AppleSceneLayout._();

  static const appleRadius = 20.0;
  static const basketBodyDepth = 115.0;
  static const basketCenterX = 200.0;
  static const basketHalfWidth = 110.0;
  static const basketRimLift = 26.0;
  static const basketTopY = 130.0;
  static const height = 270.0;
  static const slotAreaHeight = 82.0;
  static const slotAreaTopInset = 25.0;
  static const slotAreaWidth = 186.0;
  static const spawnY = -32.0;
  static const width = 400.0;
}

List<ScenePoint> getAppleSlotPositions(int count) {
  if (count <= 0) {
    return const [];
  }

  final cols = math.min(3, count);
  final rows = (count / cols).ceil();
  final slotBaseY =
      AppleSceneLayout.basketTopY + AppleSceneLayout.slotAreaTopInset +
      AppleSceneLayout.slotAreaHeight - 16;
  final horizontalGap = AppleSceneLayout.slotAreaWidth / math.max(cols, 1);
  final verticalGap = math.min(
    40.0,
    AppleSceneLayout.slotAreaHeight / math.max(rows, 1),
  );
  final startX =
      AppleSceneLayout.basketCenterX - ((cols - 1) * horizontalGap) / 2;

  final positions = <ScenePoint>[];

  for (var index = 0; index < count; index++) {
    final row = index ~/ cols;
    final col = index % cols;
    final rowCols = math.min(cols, count - row * cols);
    final rowOffset = ((cols - rowCols) * horizontalGap) / 2;

    positions.add(
      ScenePoint(
        x: startX + rowOffset + col * horizontalGap,
        y: slotBaseY - row * verticalGap,
      ),
    );
  }

  return positions;
}

ScenePoint getAppleSpawnPoint(int appleIndex, int totalCount) {
  final slots = getAppleSlotPositions(math.max(totalCount, 1));
  final target = appleIndex < slots.length
      ? slots[appleIndex]
      : (slots.isNotEmpty
          ? slots[0]
          : const ScenePoint(
              x: AppleSceneLayout.basketCenterX,
              y: AppleSceneLayout.basketTopY,
            ));

  final spread = ((appleIndex % 3) - 1) * 28.0;

  return ScenePoint(
    x: target.x + spread,
    y: AppleSceneLayout.spawnY,
  );
}
