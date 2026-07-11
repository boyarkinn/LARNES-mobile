import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/math/number_row_show/number_row_reveal.dart';

void main() {
  group('getNumberRowRevealTotalMs', () {
    test('reveals all ten digits within budget', () {
      expect(getNumberRowRevealTotalMs(), lessThanOrEqualTo(numberRowRevealBudgetMs));
    });

    test('staggers digits across the row', () {
      expect(getNumberRowRevealDelayMs(0), 0);
      expect(getNumberRowRevealDelayMs(9), greaterThan(0));
      expect(
        getNumberRowRevealTotalMs(),
        getNumberRowRevealDelayMs(9) + numberRowPopMs,
      );
    });
  });
}
