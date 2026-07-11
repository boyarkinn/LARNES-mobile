import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/math/number_composition/composition_scene_layout.dart';

void main() {
  group('computeCompositionSceneLayout', () {
    test('portrait dots equation scales to fit width', () {
      final layout = computeCompositionSceneLayout(
        viewportWidth: 360,
        viewportHeight: 640,
        showDigits: false,
        isPractice: true,
      );

      expect(layout.equationScale, lessThan(1.0));
      expect(layout.dotSlotSize, lessThan(112));
      expect(layout.dotSlotSize, greaterThan(40));
    });

    test('landscape digits demo stays on one logical row budget', () {
      final layout = computeCompositionSceneLayout(
        viewportWidth: 640,
        viewportHeight: 360,
        showDigits: true,
        isPractice: false,
      );

      expect(layout.equationScale, lessThanOrEqualTo(1.0));
      expect(layout.digitSize, lessThanOrEqualTo(80));
    });
  });

  group('computeCompositionChoiceBarLayout', () {
    test('choice font fits inside button height in portrait', () {
      final layout = computeCompositionChoiceBarLayout(
        viewportWidth: 360,
        viewportHeight: 640,
        showDigits: true,
      );

      expect(layout.fontSize, lessThanOrEqualTo(layout.buttonHeight));
      expect(layout.fontSize, greaterThan(16));
      expect(layout.buttonHeight, greaterThanOrEqualTo(32));
    });

    test('dot choice size fits inside button height', () {
      final layout = computeCompositionChoiceBarLayout(
        viewportWidth: 360,
        viewportHeight: 640,
        showDigits: false,
      );

      expect(layout.dotChoiceSize, lessThanOrEqualTo(layout.buttonHeight));
      expect(layout.dotChoiceSize, greaterThan(20));
    });
  });
}
