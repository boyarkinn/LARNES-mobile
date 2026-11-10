import 'dart:async';

enum TrainerPlaybackStatus { paused, playing, complete, cancelled }

typedef TrainerTimerFactory =
    Timer Function(Duration duration, void Function() callback);

/// Owns one pending timer; navigation invalidates it before changing position.
class TrainerPlaybackController<Event> {
  TrainerPlaybackController({
    required List<Event> events,
    required this.delayBeforeMs,
    required this.onEvent,
    this.onSeek,
    this.onComplete,
    int Function()? nowMs,
    TrainerTimerFactory? timerFactory,
  }) : _events = List.unmodifiable(events),
       _nowMsOverride = nowMs,
       _timerFactory =
           timerFactory ?? ((duration, callback) => Timer(duration, callback));

  final List<Event> _events;
  final int Function(Event event, int index) delayBeforeMs;
  final void Function(Event event, int index) onEvent;
  final void Function(int nextIndex)? onSeek;
  final void Function()? onComplete;
  final Stopwatch _stopwatch = Stopwatch()..start();
  final int Function()? _nowMsOverride;
  final TrainerTimerFactory _timerFactory;

  Timer? _timer;
  int _dueAt = 0;
  int? _remainingMs;
  int _generation = 0;
  int _nextIndex = 0;
  TrainerPlaybackStatus _status = TrainerPlaybackStatus.paused;

  int get nextIndex => _nextIndex;
  TrainerPlaybackStatus get status => _status;
  int _nowMilliseconds() =>
      _nowMsOverride?.call() ?? _stopwatch.elapsedMilliseconds;

  void play() {
    if (_status == TrainerPlaybackStatus.cancelled ||
        _status == TrainerPlaybackStatus.complete ||
        _status == TrainerPlaybackStatus.playing) {
      return;
    }
    _status = TrainerPlaybackStatus.playing;
    _advance();
  }

  void pause() {
    if (_status != TrainerPlaybackStatus.playing) return;
    _status = TrainerPlaybackStatus.paused;
    if (_timer != null) {
      _timer!.cancel();
      _timer = null;
      final remaining = _dueAt - _nowMilliseconds();
      _remainingMs = remaining < 0 ? 0 : remaining;
    }
  }

  void seek(int nextIndex) {
    if (nextIndex < 0 || nextIndex > _events.length) {
      throw RangeError.range(nextIndex, 0, _events.length, 'nextIndex');
    }
    _clearWait();
    _generation++;
    _nextIndex = nextIndex;
    _status = TrainerPlaybackStatus.paused;
    onSeek?.call(nextIndex);
  }

  Event? stepForward() {
    if (_status == TrainerPlaybackStatus.cancelled ||
        _nextIndex >= _events.length) {
      return null;
    }
    pause();
    _clearWait();
    final index = _nextIndex++;
    final event = _events[index];
    final generation = _generation;
    onEvent(event, index);
    if (generation == _generation && _nextIndex == _events.length) _finish();
    return event;
  }

  void stepBackward() {
    if (_status == TrainerPlaybackStatus.cancelled) return;
    seek(_nextIndex > 0 ? _nextIndex - 1 : 0);
  }

  void replay() {
    seek(0);
    play();
  }

  void cancel() {
    _clearWait();
    _generation++;
    _status = TrainerPlaybackStatus.cancelled;
  }

  void _clearWait() {
    _timer?.cancel();
    _timer = null;
    _remainingMs = null;
  }

  void _finish() {
    if (_status == TrainerPlaybackStatus.complete) return;
    _status = TrainerPlaybackStatus.complete;
    onComplete?.call();
  }

  void _advance() {
    while (_status == TrainerPlaybackStatus.playing) {
      if (_nextIndex >= _events.length) {
        _finish();
        return;
      }

      final index = _nextIndex;
      final event = _events[index];
      final delay = _remainingMs ?? delayBeforeMs(event, index);
      if (delay < 0) throw StateError('Неверная задержка показа.');

      if (delay > 0) {
        _remainingMs = delay;
        _dueAt = _nowMilliseconds() + delay;
        _timer = _timerFactory(Duration(milliseconds: delay), () {
          _timer = null;
          _remainingMs = 0;
          _advance();
        });
        return;
      }

      _remainingMs = null;
      _nextIndex++;
      final generation = _generation;
      onEvent(event, index);
      if (generation != _generation) return;
    }
  }
}
