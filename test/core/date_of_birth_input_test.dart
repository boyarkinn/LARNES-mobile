import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/core/formatting/date_of_birth_input.dart';

void main() {
  group('DateOfBirthInputFormatter', () {
    test('inserts dots while typing digits', () {
      expect(formatDateOfBirthDigits('15'), '15');
      expect(formatDateOfBirthDigits('1503'), '15.03');
      expect(formatDateOfBirthDigits('15032018'), '15.03.2018');
    });
  });

  group('isoDateToDisplay', () {
    test('converts ISO to DD.MM.YYYY', () {
      expect(isoDateToDisplay('2018-05-01'), '01.05.2018');
      expect(isoDateToDisplay(null), '');
    });
  });

  group('displayDateToIso', () {
    test('converts complete display date to ISO', () {
      expect(displayDateToIso('15.03.2018'), '2018-03-15');
    });

    test('rejects incomplete input', () {
      expect(displayDateToIso('15.03.'), isNull);
      expect(displayDateToIso('15.03'), isNull);
    });

    test('rejects invalid calendar dates', () {
      expect(displayDateToIso('31.02.2018'), isNull);
    });

    test('rejects future dates', () {
      expect(displayDateToIso('01.01.2099'), isNull);
    });
  });

  group('parseDateOfBirthInput', () {
    test('parses ISO and display formats', () {
      expect(parseDateOfBirthInput('2018-05-01')?.year, 2018);
      expect(parseDateOfBirthInput('01.05.2018')?.month, 5);
    });
  });
}
