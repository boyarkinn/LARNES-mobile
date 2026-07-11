import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/math/number_row_show/number_row_show_geometry.dart';

void main() {
  group('getNumberRowSlots', () {
    test('lays out ten digits across the row', () {
      final slots = getNumberRowSlots();

      expect(slots.length, 10);
      expect(slots.map((slot) => slot.digit).toList(), [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]);
    });

    test('anchors digits from padding to the opposite edge', () {
      final slots = getNumberRowSlots();

      expect(slots.first.x, NumberRowLayout.paddingX);
      expect(slots.last.x, NumberRowLayout.width - NumberRowLayout.paddingX);
    });
  });
}
