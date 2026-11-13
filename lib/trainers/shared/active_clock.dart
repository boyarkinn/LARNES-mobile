class ActiveClock {
  ActiveClock(this._elapsed, {int Function()? now}) : _now = now ?? _monotonic;
  static final _stopwatch = Stopwatch()..start();
  static int _monotonic() => _stopwatch.elapsedMilliseconds;
  final int Function() _now;
  int _elapsed;
  int? _since;
  void start() {
    _since ??= _now();
  }

  int read() =>
      _elapsed + (_since == null ? 0 : (_now() - _since!).clamp(0, 1 << 50));
  int pause() {
    _elapsed = read();
    _since = null;
    return _elapsed;
  }
}
