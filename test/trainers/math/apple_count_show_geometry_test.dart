import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/math/apple_count_show/apple_count_show_geometry.dart';

void main() {
  group('getAppleSlotPositions', () {
    test('returns empty slots for zero apples', () {
      expect(getAppleSlotPositions(0), isEmpty);
    });

    test('centers a single apple in the basket', () {
      final slots = getAppleSlotPositions(1);

      expect(slots.single.x, AppleSceneLayout.basketCenterX);
    });

    test('lays out nine apples in three rows', () {
      final slots = getAppleSlotPositions(9);

      expect(slots.length, 9);
      expect(slots.map((slot) => slot.y).toSet().length, 3);
    });
  });

  group('getAppleSpawnPoint', () {
    test('spawns apples above the basket rim', () {
      final spawn = getAppleSpawnPoint(0, 2);

      expect(spawn.y < AppleSceneLayout.basketTopY, isTrue);
    });
  });
}
