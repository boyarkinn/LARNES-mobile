import 'package:larnes_mobile/trainers/shared/abacus/abacus_model.dart';

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

TripleRepresentation getTripleRepresentation(int value, int totalRods) {
  final safeValue = value < 0 ? 0 : value.truncate();

  return TripleRepresentation(
    dotCount: safeValue,
    rods: numberToAbacus(safeValue, totalRods),
    value: safeValue,
  );
}
