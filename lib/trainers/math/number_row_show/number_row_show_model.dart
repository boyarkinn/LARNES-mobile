const numberRowDigits = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];

int normalizeStudyDigit(num digit) {
  if (!digit.isFinite) {
    return 0;
  }
  final value = digit.truncate();
  if (value <= 0) {
    return 0;
  }
  if (value >= 9) {
    return 9;
  }
  return value;
}

bool isStudyDigit(int value, int studyDigit) {
  return value == normalizeStudyDigit(studyDigit);
}
