import 'package:larnes_mobile/trainers/shared/shuffled_cycle.dart';

class TimedWordSession {
  const TimedWordSession({
    required this.phase,
    required this.round,
    required this.counts,
    required this.orderSeed,
    required this.order,
    required this.elapsedMs,
  });
  final String phase;
  final int round, orderSeed, elapsedMs;
  final List<int> counts, order;
  factory TimedWordSession.create(int size, int seed, int rounds) =>
      TimedWordSession(
        phase: 'intro',
        round: 0,
        counts: List.filled(rounds, 0),
        orderSeed: seed & 0xffffffff,
        order: ShuffledCycle.create(size, seed).order,
        elapsedMs: 0,
      );
  TimedWordSession copy({
    String? phase,
    int? round,
    List<int>? counts,
    int? elapsedMs,
  }) => TimedWordSession(
    phase: phase ?? this.phase,
    round: round ?? this.round,
    counts: counts ?? this.counts,
    orderSeed: orderSeed,
    order: order,
    elapsedMs: elapsedMs ?? this.elapsedMs,
  );
  TimedWordSession tick(int elapsed, List<int> durations) {
    if (phase != 'reading') return this;
    final next = copy(elapsedMs: elapsed > elapsedMs ? elapsed : elapsedMs);
    if (next.elapsedMs < durations[round]) return next;
    return round + 1 < durations.length
        ? next.copy(phase: 'prompt', round: round + 1, elapsedMs: 0)
        : next.copy(phase: 'result', elapsedMs: durations[round]);
  }

  TimedWordSession confirm(int elapsed, List<int> durations) {
    final timed = tick(elapsed, durations);
    if (timed.phase != 'reading') return timed;
    final next = [...counts];
    next[round]++;
    return timed.copy(counts: next);
  }

  int get wordIndex => order[counts[round] % order.length];
  Map<String, dynamic> toJson() => {
    'phase': phase,
    'round': round,
    'counts': counts,
    'orderSeed': orderSeed,
    'order': order,
    'elapsedMs': elapsedMs,
  };
  static TimedWordSession? restore(dynamic raw, int size, List<int> durations) {
    if (raw is! Map ||
        raw['counts'] is! List ||
        raw['order'] is! List ||
        raw['round'] is! int ||
        raw['orderSeed'] is! int ||
        raw['elapsedMs'] is! int) {
      return null;
    }
    final counts = (raw['counts'] as List).whereType<int>().toList(),
        order = (raw['order'] as List).whereType<int>().toList();
    final round = raw['round'] as int;
    if (![
          'intro',
          'ready',
          'reading',
          'prompt',
          'result',
        ].contains(raw['phase']) ||
        counts.length != durations.length ||
        counts.any((n) => n < 0 || n > 1000000) ||
        order.length != size ||
        order.toSet().length != size ||
        order.any((n) => n < 0 || n >= size) ||
        round < 0 ||
        round >= durations.length ||
        raw['elapsedMs'] < 0) {
      return null;
    }
    return TimedWordSession(
      phase: raw['phase'],
      round: round,
      counts: counts,
      orderSeed: raw['orderSeed'],
      order: order,
      elapsedMs: raw['elapsedMs'],
    );
  }
}
