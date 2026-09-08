import 'package:larnes_mobile/trainers/mental_arithmetic/dots_digit_abacus/dots_digit_abacus_sizes.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_model.dart';

export 'dots_digit_abacus_sizes.dart'
    show kDotsDigitAbacusMaxValue, kDotsDigitAbacusTotalRods;

class TripleRepresentation {
  const TripleRepresentation({
    required this.dotCount,
    required this.rods,
    required this.value,
  });

  final int dotCount;
  final List<RodState> rods;
  final int value;
}

int getMaxValueForRods(int totalRods) {
  return getMaxValueForAbacusRods(totalRods);
}

int normalizeDotsDigitAbacusValue(Object? raw) {
  final parsed = switch (raw) {
    final int value => value,
    final num value => value.toInt(),
    final String value => int.tryParse(value),
    _ => null,
  };

  if (parsed == null) {
    return 0;
  }

  return parsed.clamp(0, kDotsDigitAbacusMaxValue);
}

TripleRepresentation getTripleRepresentation(int value, int totalRods) {
  final safeValue = normalizeDotsDigitAbacusValue(value);

  return TripleRepresentation(
    dotCount: safeValue,
    rods: numberToAbacus(safeValue, totalRods),
    value: safeValue,
  );
}

/// Счёт точек в explain: с 1, кроме target=0 — тогда только «ноль».
int getExplainDotCountStart(int value) {
  final safeValue = normalizeDotsDigitAbacusValue(value);

  return safeValue == 0 ? 0 : 1;
}
