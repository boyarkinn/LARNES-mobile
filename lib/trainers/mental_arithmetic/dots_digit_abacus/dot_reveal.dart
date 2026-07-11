/// Web v2: `platform/src/trainers/mental-arithmetic/dots-digit-abacus/dot-reveal.ts`

/// Интервал между появлением точек для счёта вслух.
const dotRevealIntervalMs = 500;

/// Alias for tests (web `DOT_REVEAL_INTERVAL_MS`).
const kDotRevealIntervalMs = dotRevealIntervalMs;

/// Длительность фазы счёта до «= цифра = абакус».
int getDotPhaseDurationMs(int count) {
  if (count <= 0) {
    return 0;
  }

  return count * dotRevealIntervalMs;
}
