import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/math/number_row_show/number_row_show_model.dart';

void main() {
  group('normalizeStudyDigit', () {
    test('clamps to 0-9', () {
      expect(normalizeStudyDigit(-2), 0);
      expect(normalizeStudyDigit(4), 4);
      expect(normalizeStudyDigit(9), 9);
      expect(normalizeStudyDigit(15), 9);
    });

    test('covers full number row', () {
      expect(numberRowDigits, [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]);
    });
  });

  group('isStudyDigit', () {
    test('matches only the study digit', () {
      expect(isStudyDigit(3, 3), isTrue);
      expect(isStudyDigit(2, 3), isFalse);
    });
  });
}
