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

List<DigitSlot> getNumberRowSlots(int studyDigit) {
  final digits = getRowDigits(studyDigit);
  final innerWidth = NumberRowLayout.width - NumberRowLayout.paddingX * 2;
  final step = digits.length > 1 ? innerWidth / (digits.length - 1) : 0.0;

  return List.generate(digits.length, (index) {
    return DigitSlot(
      digit: digits[index],
      x: NumberRowLayout.paddingX + index * step,
    );
  });
}

double numberRowSceneWidthForDigit(int studyDigit) {
  final slotCount = getRowDigits(normalizeStudyDigit(studyDigit)).length;
  if (slotCount >= 10) {
    return NumberRowLayout.width;
  }
  return (NumberRowLayout.paddingX * 2 + (slotCount - 1) * 36)
      .clamp(220, NumberRowLayout.width)
      .toDouble();
}
