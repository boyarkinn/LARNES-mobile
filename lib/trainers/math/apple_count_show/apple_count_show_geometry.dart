import 'dart:math' as math;

class ScenePoint {
  const ScenePoint({required this.x, required this.y});

  final double x;
  final double y;
}

class AppleSceneLayout {
  const AppleSceneLayout._();

  static const appleRadius = 16.0;
  static const basketCenterX = 160.0;
  static const basketTopY = 148.0;
  static const height = 280.0;
  static const slotAreaHeight = 56.0;
  static const slotAreaWidth = 120.0;
  static const spawnY = 36.0;
  static const width = 320.0;
}

List<ScenePoint> getAppleSlotPositions(int count) {
  if (count <= 0) {
    return const [];
  }

  final cols = count < 3 ? count : 3;
  final rows = (count / cols).ceil();
  final slotBaseY = AppleSceneLayout.basketTopY + AppleSceneLayout.slotAreaHeight - 12;
  final horizontalGap = AppleSceneLayout.slotAreaWidth / (cols > 0 ? cols : 1);
  final verticalGap = math.min(
    28.0,
    AppleSceneLayout.slotAreaHeight / (rows > 0 ? rows : 1),
  );
  final startX = AppleSceneLayout.basketCenterX - ((cols - 1) * horizontalGap) / 2;

  final positions = <ScenePoint>[];

  for (var index = 0; index < count; index++) {
    final row = index ~/ cols;
    final col = index % cols;
    final rowCols = cols < count - row * cols ? cols : count - row * cols;
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
  final slots = getAppleSlotPositions(totalCount > 0 ? totalCount : 1);
  final target = appleIndex < slots.length
      ? slots[appleIndex]
      : (slots.isNotEmpty
          ? slots[0]
          : const ScenePoint(
              x: AppleSceneLayout.basketCenterX,
              y: AppleSceneLayout.basketTopY,
            ));

  final spread = ((appleIndex % 3) - 1) * 22.0;

  return ScenePoint(
    x: target.x + spread,
    y: AppleSceneLayout.spawnY,
  );
}
