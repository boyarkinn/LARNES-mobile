int normalizeDigit(num digit) {
  if (!digit.isFinite) {
    return 0;
  }
  return digit.truncate().clamp(0, 1 << 30);
}

int digitToAppleCount(num digit) {
  return normalizeDigit(digit);
}
