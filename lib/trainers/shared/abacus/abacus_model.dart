class RodState {
  const RodState({
    required this.heavenUp,
    required this.earthCount,
  });

  final bool heavenUp;
  final int earthCount;

  @override
  bool operator ==(Object other) {
    return other is RodState &&
        other.heavenUp == heavenUp &&
        other.earthCount == earthCount;
  }

  @override
  int get hashCode => Object.hash(heavenUp, earthCount);
}

RodState digitToBeads(int digit) {
  final normalized = ((digit.truncate() % 10) + 10) % 10;
  final heavenUp = normalized >= 5;

  return RodState(
    heavenUp: heavenUp,
    earthCount: heavenUp ? normalized - 5 : normalized,
  );
}

int beadsToDigit(RodState state) {
  return (state.heavenUp ? 5 : 0) + state.earthCount;
}

List<RodState> numberToAbacus(int value, int totalRods) {
  if (totalRods < 1) {
    return const [];
  }

  var remaining = value < 0 ? 0 : value.truncate();
  final digits = <int>[];

  for (var index = 0; index < totalRods; index++) {
    digits.insert(0, remaining % 10);
    remaining ~/= 10;
  }

  return digits.map(digitToBeads).toList();
}

int abacusToNumber(List<RodState> rods) {
  var total = 0;
  for (var index = 0; index < rods.length; index++) {
    final place = rods.length - 1 - index;
    total += beadsToDigit(rods[index]) * _pow10(place);
  }
  return total;
}

List<RodState> emptyRods(int totalRods) {
  return List.generate(
    totalRods,
    (_) => const RodState(heavenUp: false, earthCount: 0),
  );
}

int getMaxValueForAbacusRods(int totalRods) {
  if (totalRods < 1) {
    return 0;
  }
  return _pow10(totalRods) - 1;
}

int _pow10(int exponent) {
  var result = 1;
  for (var i = 0; i < exponent; i++) {
    result *= 10;
  }
  return result;
}
