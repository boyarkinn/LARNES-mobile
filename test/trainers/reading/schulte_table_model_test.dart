import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/reading/schulte_table/model.dart';

double Function() sequenceRng(List<double> values) {
  var index = 0;
  return () {
    final value = index < values.length ? values[index] : 0.99;
    index += 1;
    return value;
  };
}

SchulteCell? cellAtCenter(SchulteTable table, SchulteCenterCell center) {
  for (final cell in table.cells) {
    if (cell.row == center.row && cell.col == center.col) {
      return cell;
    }
  }
  return null;
}

void main() {
  group('schulte-table model', () {
    test('keeps 100 digits and 66 russian letters', () {
      expect(schulteDigits.length, 100);
      expect(schulteLetters.length, 66);
      expect(schulteLetters.first, 'А');
      expect(schulteLetters[33], 'а');
    });

    test('builds a 5×5 digit table with unique 1–25', () {
      final table = generateSchulteTable(
        const GenerateSchulteTableInput(
          category: 'digits',
          gridSize: 5,
          order: 'forward',
          random: _zero,
        ),
      );

      expect(table.size, 5);
      expect(table.cells.length, 25);
      expect(table.sequence, List.generate(25, (index) => '${index + 1}'));
      expect(
        [...table.cells.map((cell) => cell.value)]
          ..sort((left, right) => int.parse(left) - int.parse(right)),
        table.sequence,
      );
    });

    test('places the first search target in a center cell', () {
      final table = generateSchulteTable(
        const GenerateSchulteTableInput(
          category: 'digits',
          gridSize: 5,
          order: 'forward',
          random: _zero,
        ),
      );
      final center = getSchulteCenterCells(5).first;

      expect(cellAtCenter(table, center)?.value, '1');
      expect(table.sequence.first, '1');
    });

    test('puts the last number in the center for backward order', () {
      final table = generateSchulteTable(
        const GenerateSchulteTableInput(
          category: 'digits',
          gridSize: 5,
          order: 'backward',
          random: _zero,
        ),
      );
      final center = getSchulteCenterCells(5).first;

      expect(table.sequence.take(3), ['25', '24', '23']);
      expect(cellAtCenter(table, center)?.value, '25');
    });

    test('builds a letter sequence with capitals before lowercase', () {
      expect(
        buildSchulteSequence(['б', 'А', 'а', 'Б'], 'letters', 'forward'),
        ['А', 'Б', 'а', 'б'],
      );
      expect(
        buildSchulteSequence(['б', 'А', 'а', 'Б'], 'letters', 'backward'),
        ['б', 'а', 'Б', 'А'],
      );
    });

    test('fills an 8×8 letter table from the first 64 letters', () {
      final table = generateSchulteTable(
        GenerateSchulteTableInput(
          category: 'letters',
          gridSize: 8,
          order: 'forward',
          random: sequenceRng([0.2, 0.4, 0.1]),
        ),
      );

      expect(table.cells.length, 64);
      expect(table.sequence.first, 'А');
      expect(table.cells.map((cell) => cell.value).toSet().length, 64);
    });

    test('accepts only the next value in the search chain', () {
      const sequence = ['1', '2', '3'];

      expect(isNextSchulteTarget('1', sequence, 0), isTrue);
      expect(isNextSchulteTarget('2', sequence, 0), isFalse);
      expect(isNextSchulteTarget('2', sequence, 1), isTrue);
      expect(isNextSchulteTarget('3', sequence, 3), isFalse);
    });

    test('rejects a letter table larger than the alphabet pool', () {
      expect(
        () => generateSchulteTable(
          const GenerateSchulteTableInput(
            category: 'letters',
            gridSize: 9,
            order: 'forward',
          ),
        ),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            contains('Not enough letters'),
          ),
        ),
      );
    });
  });
}

double _zero() => 0;
