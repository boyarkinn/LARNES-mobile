import 'package:larnes_mobile/trainers/math/number_row_show/number_row_show_model.dart';

class NumberRowLayout {
  const NumberRowLayout._();

  static const activeFontSize = 56.0;
  static const baselineY = 88.0;
  static const height = 140.0;
  static const inactiveFontSize = 34.0;
  static const paddingX = 20.0;
  static const width = 360.0;
}

class DigitSlot {
  const DigitSlot({required this.digit, required this.x});

  final int digit;
  final double x;
}

List<DigitSlot> getNumberRowSlots() {
  final innerWidth = NumberRowLayout.width - NumberRowLayout.paddingX * 2;
  final step = innerWidth / (numberRowDigits.length - 1);

  return List.generate(numberRowDigits.length, (index) {
    return DigitSlot(
      digit: numberRowDigits[index],
      x: NumberRowLayout.paddingX + index * step,
    );
  });
}
