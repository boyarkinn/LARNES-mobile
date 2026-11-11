/// Semantic cue keys match the web gesture catalog. Text and recordings live in the server catalog.
String earthCycleCue(String hand, int digit) =>
    'explanation:abacus-gesture:earth-cycle:$hand:$digit';

String heavenCue(String hand, String direction) =>
    'explanation:abacus-gesture:heaven:$hand:$direction';

String crabCue(
  String hand,
  int digit,
  String action, {
  String context = 'simple',
}) => 'explanation:abacus-gesture:crab:$context:$hand:$digit:$action';

String friendsCue(int digit) => 'explanation:abacus-gesture:friends:$digit';

const friendsSeedCue = 'explanation:abacus-gesture:friends:seed';

String warmupIntroCue(String type) => 'explanation:abacus-warmup:intro:$type';

String simpleSetCue(String hand, int digit) {
  if (digit >= 1 && digit <= 4) return earthCycleCue(hand, digit);
  if (digit == 5) return heavenCue(hand, 'down');
  if (digit >= 6 && digit <= 9) return crabCue(hand, digit - 5, 'close');
  throw RangeError.range(digit, 1, 9, 'digit');
}

String? simpleClearCue(String hand, int digit) {
  if (digit >= 1 && digit <= 4) return null;
  if (digit == 5) return heavenCue(hand, 'up');
  if (digit >= 6 && digit <= 9) return crabCue(hand, digit - 5, 'open');
  throw RangeError.range(digit, 1, 9, 'digit');
}
