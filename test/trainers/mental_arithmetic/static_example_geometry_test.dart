import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/static_example_show/move_hints.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/static_example_show/static_example_geometry.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_geometry.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_model.dart';

void main() {
  group('layoutMoveOverlay travel zone', () {
    test('spans full earthTravel for earth-from-bar', () {
      final layout = layoutMoveOverlay(
        kind: MoveOverlayKind.earthFromBar,
        rodIndex: 0,
        slotIndex: 0,
        state: const RodState(heavenUp: false, earthCount: 1),
        totalRods: 2,
      );

      expect(layout.height, greaterThanOrEqualTo(AbacusLayout.earthTravel + AbacusLayout.beadHeight));
      expect(layout.arrowDirection, 'down');
      expect(layout.polarity, 'subtract');
      expect(layout.arrowX, lessThan(AbacusLayout.beadHalfWidth));
    });

    test('points heaven-from-bar arrow up', () {
      final layout = layoutMoveOverlay(
        kind: MoveOverlayKind.heavenFromBar,
        rodIndex: 0,
        slotIndex: 0,
        state: const RodState(heavenUp: true, earthCount: 0),
        totalRods: 1,
      );

      expect(layout.arrowDirection, 'up');
      expect(layout.polarity, 'subtract');
    });

    test('expands viewBox so 10 − 9 overlays are not clipped', () {
      final rods = numberToAbacus(10, 2);
      final moveOverlays = resolveMoveOverlays(
        operation: 'subtract',
        operandA: 10,
        operandB: 9,
        totalRods: 2,
      );
      final viewBox = abacusViewBoxWithMoveOverlays(2, moveOverlays, rods);

      expect(viewBox.viewBoxX, lessThan(0));
      expect(viewBox.viewBoxWidth, greaterThan(viewBox.base.width));
    });

    test('merges multiple earth overlays on one rod into a single field', () {
      final rods = numberToAbacus(2, 1);
      final moveOverlays = resolveMoveOverlays(
        operation: 'add',
        operandA: 2,
        operandB: 3,
        totalRods: 1,
      );

      expect(moveOverlays.length, greaterThan(1));

      final layouts = layoutMoveOverlays(moveOverlays, rods, 1);
      final earthSubtractLayouts = layouts
          .where(
            (layout) => layout.polarity == 'subtract' && layout.arrowDirection == 'down',
          )
          .toList();

      expect(earthSubtractLayouts.length, 1);
      expect(
        earthSubtractLayouts.first.height,
        greaterThan(AbacusLayout.earthTravel + AbacusLayout.beadHeight),
      );
    });

    test('5 − 1 renders heaven up and merged earth up overlays', () {
      final rods = numberToAbacus(5, 1);
      final moveOverlays = resolveMoveOverlays(
        operation: 'subtract',
        operandA: 5,
        operandB: 1,
        totalRods: 1,
      );
      final layouts = layoutMoveOverlays(moveOverlays, rods, 1);

      expect(layouts.length, 2);
      expect(
        layouts.map((layout) => '${layout.polarity}:${layout.arrowDirection}').toList(),
        ['subtract:up', 'add:up'],
      );
    });
  });
}
