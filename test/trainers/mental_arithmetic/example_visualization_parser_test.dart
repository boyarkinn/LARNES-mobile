import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/example_visualization/example_parser.dart';

void main() {
  group('parseExampleActions', () {
    test('parses one line with multiple actions', () {
      expect(
        parseExampleActions('+2 -1').map((a) => (a.sign, a.digit)).toList(),
        [('+', 2), ('-', 1)],
      );
      expect(
        parseExampleActions('+1 +2 -1').map((a) => (a.sign, a.digit)).toList(),
        [('+', 1), ('+', 2), ('-', 1)],
      );
      expect(parseExampleActions('+5').single.digit, 5);
    });

    test('normalizes spaced signs and unicode minus', () {
      expect(normalizeExampleString('+2 - 1'), '+2 -1');
      expect(
        parseExampleActions('+2 - 1').map((a) => (a.sign, a.digit)).toList(),
        parseExampleActions('+2 -1').map((a) => (a.sign, a.digit)).toList(),
      );
      expect(
        parseExampleActions('+2 −1').map((a) => (a.sign, a.digit)).toList(),
        parseExampleActions('+2 -1').map((a) => (a.sign, a.digit)).toList(),
      );
    });

    test('rejects invalid format', () {
      expect(() => parseExampleActions(''), throwsFormatException);
      expect(() => parseExampleActions('2 -1'), throwsFormatException);
      expect(() => parseExampleActions('+0 -1'), throwsFormatException);
    });
  });
}
