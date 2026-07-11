import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/shared/param_coerce.dart';

void main() {
  group('coerceInt', () {
    test('accepts int and truncates double', () {
      expect(coerceInt(3), 3);
      expect(coerceInt(3.9), 3);
    });

    test('parses numeric strings like z.coerce.number().int()', () {
      expect(coerceInt('7'), 7);
      expect(coerceInt('0'), 0);
    });

    test('rejects non-integer strings', () {
      expect(coerceInt('3.7'), isNull);
      expect(coerceInt('abc'), isNull);
      expect(coerceInt(''), isNull);
    });
  });

  group('coerceDouble', () {
    test('accepts int, double and numeric strings', () {
      expect(coerceDouble(2), 2);
      expect(coerceDouble(2.5), 2.5);
      expect(coerceDouble('3.5'), 3.5);
    });

    test('rejects invalid strings', () {
      expect(coerceDouble('nope'), isNull);
    });
  });

  group('coerceIntList', () {
    test('parses homogeneous int list', () {
      expect(coerceIntList([1, 2, 3]), [1, 2, 3]);
      expect(coerceIntList(['4', 5]), [4, 5]);
    });

    test('rejects mixed invalid list', () {
      expect(coerceIntList([1, 'x']), isNull);
      expect(coerceIntList('1,2'), isNull);
    });
  });
}
