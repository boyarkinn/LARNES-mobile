import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/math/number_row_show/number_row_show_model.dart';

void main() {
  group('normalizeStudyDigit', () {
    test('clamps to 1-9', () {
      expect(normalizeStudyDigit(-2), 1);
      expect(normalizeStudyDigit(0), 1);
      expect(normalizeStudyDigit(4), 4);
      expect(normalizeStudyDigit(9), 9);
      expect(normalizeStudyDigit(15), 9);
    });
  });

  group('getRowDigits', () {
    test('returns 0..N inclusive', () {
      expect(getRowDigits(4), [0, 1, 2, 3, 4]);
    });
  });

  group('isStudyDigit', () {
    test('matches only the study digit', () {
      expect(isStudyDigit(3, 3), isTrue);
      expect(isStudyDigit(2, 3), isFalse);
    });
  });
}
