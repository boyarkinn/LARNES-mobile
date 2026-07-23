import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_geometry.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_model.dart';

void main() {
  group('layoutRodBeads earth zone', () {
    test('moves bead 0 a full earthTravel between all-down and first-up', () {
      const down = RodState(heavenUp: false, earthCount: 0);
      const up = RodState(heavenUp: false, earthCount: 1);

      final downLayout = layoutRodBeads(down);
      final upLayout = layoutRodBeads(up);

      expect(
        downLayout.earthYs[0] - upLayout.earthYs[0],
        AbacusLayout.earthTravel,
      );
    });

    test('keeps inactive earth beads stacked at the bottom when some are raised', () {
      const partial = RodState(heavenUp: false, earthCount: 2);
      final layout = layoutRodBeads(partial);

      expect(layout.earthYs[3] - layout.earthYs[2], AbacusLayout.earthGap);
      expect(layout.earthYs[2], greaterThan(layout.earthYs[1]));
    });
  });

  group('abacusViewBox', () {
    test('grows width with rod count', () {
      final oneRod = abacusViewBox(1);
      final threeRods = abacusViewBox(3);

      expect(threeRods.width, greaterThan(oneRod.width));
      expect(oneRod.height, threeRods.height);
    });
  });

  group('isMarkedEarthBead', () {
    test('marks every 3rd rod from the right (hundreds, hundred-thousands, …)', () {
      expect(isMarkedEarthBead(0, 0, 2), isFalse);
      expect(isMarkedEarthBead(1, 0, 2), isFalse);

      expect(isMarkedEarthBead(0, 0, 3), isTrue);
      expect(isMarkedEarthBead(1, 0, 3), isFalse);
      expect(isMarkedEarthBead(2, 0, 3), isFalse);

      expect(isMarkedEarthBead(1, 0, 13), isTrue);
      expect(isMarkedEarthBead(4, 0, 13), isTrue);
      expect(isMarkedEarthBead(10, 0, 13), isTrue);
      expect(isMarkedEarthBead(12, 0, 13), isFalse);
      expect(isMarkedEarthBead(1, 1, 13), isFalse);
    });
  });
}
