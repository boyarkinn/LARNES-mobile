import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/reading/wedge_tables/model.dart';
import 'package:larnes_mobile/trainers/reading/wedge_tables/wedge_syllables.dart';
import 'package:larnes_mobile/trainers/reading/wedge_tables/wedge_tables_sizes.dart';

double Function() sequenceRng(List<double> values) {
  var index = 0;
  return () {
    final value = index < values.length ? values[index] : 0.99;
    index += 1;
    return value;
  };
}

void main() {
  group('wedge-tables model', () {
    test('keeps digits 0–9 and 33 russian letters', () {
      expect(kWedgeDigits.length, 10);
      expect(kWedgeLetters.length, 33);
      expect(kWedgeLetters.first, 'А');
      expect(kWedgeLetters, contains('Ё'));
    });

    test('builds a digit pool and a diagnostics syllable pool', () {
      expect(getWedgePool('digits'), kWedgeDigits);
      expect(getWedgePool('letters'), kWedgeLetters);
      expect(kWedgeSyllables.length, greaterThan(20));
      expect(getWedgePool('syllables').length, kWedgeSyllables.length);
      expect(kWedgeSyllables.every((token) => token.length > 1), isTrue);
    });

    test('generates the requested number of side-token rows', () {
      final rows = generateWedgeRows(
        GenerateWedgeRowsInput(
          category: 'digits',
          random: () => 0,
          rowCount: 10,
        ),
      );

      expect(rows.length, 10);
      for (final row in rows) {
        expect(kWedgeDigits, contains(row.left));
        expect(kWedgeDigits, contains(row.right));
      }
    });

    test('mixes token kinds for the all category', () {
      final pool = getWedgePool('all');
      final kinds = pool.map(classifyWedgeToken).toSet();

      expect(kinds, contains('digits'));
      expect(kinds, contains('letters'));
      expect(kinds, contains('syllables'));

      final rows = generateWedgeRows(
        GenerateWedgeRowsInput(
          category: 'all',
          random: sequenceRng([0, 0.4, 0.8, 0.15, 0.55, 0.95]),
          rowCount: 5,
        ),
      );

      for (final row in [rows.first.left, rows.first.right, rows.last.left]) {
        expect(pool, contains(row));
      }
    });

    test('rejects a row count outside the 5…50 step', () {
      expect(
        () => generateWedgeRows(
          const GenerateWedgeRowsInput(category: 'digits', rowCount: 7),
        ),
        throwsArgumentError,
      );
    });

    test('grows arms from the first row to the last', () {
      expect(getWedgeArmProgress(0, 10), 0);
      expect(getWedgeArmProgress(9, 10), 1);
      expect(getWedgeArmLength(0, 10, 100), kWedgeArmMinVmin);
      expect(getWedgeArmLength(9, 10, 100), kWedgeArmMaxVmin);
    });
  });
}
