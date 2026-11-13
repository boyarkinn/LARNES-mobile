import 'seeded_rng.dart';

class ShuffledCycle {
  const ShuffledCycle({
    required this.order,
    required this.position,
    required this.randomState,
    required this.consumed,
  });
  final List<int> order;
  final int position, randomState, consumed;
  factory ShuffledCycle.create(int size, int seed) =>
      _shuffle(size, seed, 0, null);
  static ShuffledCycle _shuffle(
    int size,
    int seed,
    int consumed,
    int? previous,
  ) {
    if (size < 1) throw ArgumentError('empty_word_pool');
    final order = List<int>.generate(size, (i) => i);
    var state = seed & 0xffffffff;
    final random = createSeededRng(state);
    for (var i = size - 1; i > 0; i--) {
      final value = random();
      state = (value * 4294967296).floor();
      final j = (value * (i + 1)).floor();
      final item = order[i];
      order[i] = order[j];
      order[j] = item;
    }
    if (size > 1 && order.first == previous) {
      final first = order[0];
      order[0] = order[1];
      order[1] = first;
    }
    return ShuffledCycle(
      order: order,
      position: 0,
      randomState: state,
      consumed: consumed,
    );
  }

  ShuffledCycle advance() => position + 1 < order.length
      ? ShuffledCycle(
          order: order,
          position: position + 1,
          randomState: randomState,
          consumed: consumed + 1,
        )
      : _shuffle(order.length, randomState, consumed + 1, order[position]);
  Map<String, dynamic> toJson() => {
    'order': order,
    'position': position,
    'randomState': randomState,
    'consumed': consumed,
  };
  static ShuffledCycle? restore(dynamic raw, int size) {
    if (raw is! Map ||
        raw['order'] is! List ||
        raw['position'] is! int ||
        raw['randomState'] is! int ||
        raw['consumed'] is! int) {
      return null;
    }
    final order = (raw['order'] as List).whereType<int>().toList();
    if (order.length != size ||
        order.toSet().length != size ||
        order.any((i) => i < 0 || i >= size) ||
        raw['position'] < 0 ||
        raw['position'] >= size ||
        raw['consumed'] < 0) {
      return null;
    }
    return ShuffledCycle(
      order: order,
      position: raw['position'],
      randomState: raw['randomState'],
      consumed: raw['consumed'],
    );
  }
}
