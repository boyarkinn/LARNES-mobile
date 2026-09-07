import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/math/number_row_show/number_row_show_geometry.dart';

void main() {
  group('getNumberRowSlots', () {
    test('lays out digits 0..N for study digit', () {
      final slots = getNumberRowSlots(4);

      expect(slots.length, 5);
      expect(slots.map((slot) => slot.digit).toList(), [0, 1, 2, 3, 4]);
    });

    test('anchors digits from padding to the opposite edge', () {
      final slots = getNumberRowSlots(9);

      expect(slots.first.x, NumberRowLayout.paddingX);
      expect(slots.last.x, NumberRowLayout.width - NumberRowLayout.paddingX);
    });
  });
}
