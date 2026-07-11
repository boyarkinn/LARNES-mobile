import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/math/fruit_count_tap/fruit_answer_bar_layout.dart';

void main() {
  group('computeFruitAnswerBarLayout', () {
    test('keeps font inside button height on portrait', () {
      final layout = computeFruitAnswerBarLayout(
        viewportWidth: 360,
        viewportHeight: 640,
      );

      expect(layout.fontSize, lessThanOrEqualTo(layout.buttonHeight));
      expect(layout.totalHeight, lessThanOrEqualTo(640 * 0.16 + 8));
    });

    test('fits answer bar inside a landscape stage', () {
      final layout = computeFruitAnswerBarLayout(
        viewportWidth: 780,
        viewportHeight: 360,
      );

      expect(layout.totalHeight, lessThanOrEqualTo(360 * 0.16 + 8));
      expect(layout.fontSize, lessThanOrEqualTo(layout.buttonHeight));
      expect(layout.buttonHeight, greaterThanOrEqualTo(32));
    });
  });
}
