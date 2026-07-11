import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/dots_digit_abacus/triple_scene_layout.dart';

void main() {
  group('computeTripleSceneLayout', () {
    test('keeps digit card and font inside a portrait cell', () {
      final layout = computeTripleSceneLayout(
        viewportWidth: 360,
        viewportHeight: 580,
        dotCount: 2,
      );

      expect(layout.digitCardSize, lessThanOrEqualTo(layout.cellWidth * 0.95));
      expect(layout.digitFontSize, lessThanOrEqualTo(layout.digitCardSize));
      expect(layout.abacusWidth, lessThanOrEqualTo(layout.cellWidth * 0.95));
    });

    test('caps abacus width by viewport height in landscape', () {
      final layout = computeTripleSceneLayout(
        viewportWidth: 780,
        viewportHeight: 360,
        dotCount: 2,
      );

      expect(layout.abacusWidth, lessThanOrEqualTo(layout.cellWidth * 0.95));
      expect(layout.abacusWidth, lessThan(780 * 0.36));
      expect(layout.abacusHeight, lessThanOrEqualTo(360 * 0.50));
    });

    test('shrinks dot frame to the shared cell width', () {
      final layout = computeTripleSceneLayout(
        viewportWidth: 320,
        viewportHeight: 480,
        dotCount: 9,
      );

      expect(layout.dotFrameWidth, lessThanOrEqualTo(layout.cellWidth * 0.95));
      expect(layout.dotFrameHeight, lessThanOrEqualTo(layout.cellWidth * 0.95));
    });
  });
}
