import 'package:larnes_mobile/trainers/mental_arithmetic/example_visualization/moving_bead_highlights.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_model.dart';
import 'package:test/test.dart';

void main() {
  group('resolveMovingBeadHighlights', () {
    test('+2 on empty rod highlights raising earth beads', () {
      final highlights = resolveMovingBeadHighlights(
        [digitToBeads(0)],
        [digitToBeads(2)],
      );

      expect(highlights.single.raisingEarthIndices, {0, 1});
      expect(highlights.single.heaven, isNull);
    });

    test('+5 highlights raising heaven bead', () {
      final highlights = resolveMovingBeadHighlights(
        [digitToBeads(0)],
        [digitToBeads(5)],
      );

      expect(highlights.single.heaven, BeadMoveDirection.raise);
    });

    test('-1 from 2 highlights lowering earth bead', () {
      final highlights = resolveMovingBeadHighlights(
        [digitToBeads(2)],
        [digitToBeads(1)],
      );

      expect(highlights.single.loweringEarthIndices, {1});
    });
  });
}
