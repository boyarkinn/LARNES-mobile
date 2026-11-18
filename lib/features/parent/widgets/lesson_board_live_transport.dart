import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'package:uuid/uuid.dart';

/// The actual fallback loop also guards against a late timer tick after WS takes over.
Timer startLessonBoardFallbackPolling({
  required Future<void> Function() pull,
  required bool Function() socketActive,
}) {
  if (!socketActive()) unawaited(pull());
  return Timer.periodic(const Duration(milliseconds: 500), (_) {
    if (!socketActive()) unawaited(pull());
  });
}

abstract class LessonLiveSocket {
  Stream<dynamic> get messages;
  Future<void> send(String text);
  Future<void> close();
}

class _NativeSocket implements LessonLiveSocket {
  _NativeSocket(this.socket);
  final WebSocket socket;
  @override
  Stream<dynamic> get messages => socket;
  @override
  Future<void> send(String text) => socket.addStream(Stream.value(text));
  @override
  Future<void> close() async {
    await socket.close();
  }
}

/// Sole native board socket. The shared SDK decodes v2/chunks and animates locally.
class LessonBoardLiveTransport {
  LessonBoardLiveTransport({
    required this.apiBase,
    required this.ticket,
    required this.receive,
    required this.changed,
    required this.isCurrent,
    this.connect,
    String? connectionId,
  }) : connectionId = connectionId ?? const Uuid().v4();
  final Uri apiBase;
  final Future<Map<String, dynamic>?> Function(String connectionId) ticket;
  final Future<String> Function(Map<String, dynamic> frame) receive;
  final void Function(bool active) changed;
  final bool Function() isCurrent;
  final Future<LessonLiveSocket> Function(Uri uri)? connect;
  final String connectionId;
  LessonLiveSocket? _socket;
  StreamSubscription<dynamic>? _subscription;
  Timer? _retry, _renew, _heartbeat;
  Map<String, dynamic>? _scope;
  String _lease = '';
  bool _closed = false,
      _awake = true,
      _opening = false,
      _active = false,
      _draining = false;
  int _generation = 0,
      _sequence = 0,
      _pending = 0,
      _outgoing = 0,
      _failures = 0;
  DateTime _heard = DateTime.now(), _sent = DateTime.now();
  dynamic _pointer;
  final _frames = Queue<(Map<String, dynamic>, int)>();
  Future<void> _writes = Future.value();
  bool get active => _active;
  int get generation => _generation;
  bool get _current => !_closed && _awake && isCurrent();
  void start() {
    if (_heartbeat != null) return;
    _heartbeat = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (!_current || _socket == null) return;
      if (DateTime.now().difference(_heard) > const Duration(seconds: 7)) {
        reconnect();
        return;
      }
      if (_active &&
          DateTime.now().difference(_sent) > const Duration(milliseconds: 1500))
        unawaited(
          sendSamples([
            {'kind': 'cursor', 'pointer': _pointer},
          ]),
        );
    });
    unawaited(_open());
  }

  void _setActive(bool value) {
    if (value == _active) return;
    _active = value;
    changed(value);
  }

  Future<void> _open() async {
    if (!_current || _opening || _socket != null) return;
    _opening = true;
    final gen = _generation;
    try {
      final grant = await ticket(
        connectionId,
      ).timeout(const Duration(seconds: 3));
      if (!_current || gen != _generation) return;
      if (grant?['accepted'] != true) {
        _opening = false;
        _schedule(
          grant == null || grant['reason'] == 'unavailable'
              ? 60
              : 1 << (_failures++).clamp(0, 5),
        );
        return;
      }
      if (grant?['scope'] is! Map || grant?['ticket'] is! String)
        throw StateError('invalid_live_ticket');
      _scope = Map<String, dynamic>.from(grant!['scope'] as Map);
      final uri = apiBase.replace(
        scheme: apiBase.scheme == 'https' ? 'wss' : 'ws',
        path: '/api/classroom/lesson-live',
        query: null,
        fragment: null,
      );
      final socket =
          await (connect?.call(uri) ??
                  WebSocket.connect(
                    uri.toString(),
                    headers: {'Origin': apiBase.origin},
                  ).then<LessonLiveSocket>(_NativeSocket.new))
              .timeout(const Duration(seconds: 3));
      if (!_current || gen != _generation) {
        await socket.close();
        return;
      }
      _socket = socket;
      _heard = DateTime.now();
      _sequence = 0;
      _subscription = socket.messages.listen(
        _incoming,
        onError: (_) => reconnect(),
        onDone: reconnect,
      );
      await _hello(grant);
    } catch (_) {
      if (gen == _generation) reconnect();
    } finally {
      if (gen == _generation) _opening = false;
    }
  }

  Future<bool> _write(Map<String, dynamic> value) {
    final socket = _socket, gen = _generation;
    if (!_current || socket == null) return Future.value(false);
    final text = jsonEncode({
          'type': 'lesson-board-live',
          'version': 1,
          'connectionId': connectionId,
          if (value['kind'] != 'hello') 'leaseId': _lease,
          ...value,
        }),
        size = utf8.encode(text).length;
    if (size > 32768 || _outgoing + size > 131072) {
      reconnect();
      return Future.value(false);
    }
    _outgoing += size;
    final result = Completer<bool>();
    _writes = _writes.then((_) async {
      if (!_current || gen != _generation) {
        result.complete(false);
        return;
      }
      try {
        await socket.send(text).timeout(const Duration(seconds: 2));
        result.complete(true);
      } catch (_) {
        result.complete(false);
        if (gen == _generation) reconnect();
      } finally {
        if (gen == _generation) _outgoing -= size;
      }
    });
    return result.future;
  }

  Future<void> _hello(Map<String, dynamic> grant) async {
    final features = grant['features'];
    await _write({
      'kind': 'hello',
      'ticket': grant['ticket'],
      'features': [
        'cursor',
        'stroke',
        'transform',
        'state-v2',
        if (features is List)
          ...['translate', 'create-shape'].where(features.contains),
      ],
    });
  }

  Future<void> _refresh() async {
    final gen = _generation;
    try {
      final grant = await ticket(
        connectionId,
      ).timeout(const Duration(seconds: 3));
      if (!_current || gen != _generation) return;
      if (grant?['accepted'] != true ||
          jsonEncode(grant?['scope']) != jsonEncode(_scope)) {
        reconnect();
        return;
      }
      await _hello(grant!);
    } catch (_) {
      if (gen == _generation) reconnect();
    }
  }

  void _incoming(dynamic text) {
    if (!_current || text is! String || text.length > 2097152) {
      reconnect();
      return;
    }
    try {
      final size = utf8.encode(text).length;
      if (_pending + size > 2097152) throw StateError('live_queue');
      final value = Map<String, dynamic>.from(jsonDecode(text) as Map);
      _pending += size;
      _frames.add((value, size));
      unawaited(_drain());
    } catch (_) {
      reconnect();
    }
  }

  Future<void> _drain() async {
    if (_draining) return;
    _draining = true;
    final gen = _generation;
    try {
      while (_current && gen == _generation && _frames.isNotEmpty) {
        final (frame, size) = _frames.removeFirst();
        _pending -= size;
        if (frame['type'] != 'lesson-board-live' || frame['version'] != 1)
          throw StateError('live_version');
        _heard = DateTime.now();
        if (frame['kind'] == 'ready') {
          if (frame['connectionId'] != connectionId ||
              frame['leaseId'] is! String ||
              jsonEncode(frame['scope']) != jsonEncode(_scope) ||
              _lease.isNotEmpty && frame['leaseId'] != _lease)
            throw StateError('live_scope');
          _lease = frame['leaseId'] as String;
          _renew?.cancel();
          _renew = Timer(
            const Duration(milliseconds: 2500),
            () => unawaited(_refresh()),
          );
        }
        final result = await receive(frame);
        if (!_current || gen != _generation) return;
        if (result == 'resync' || frame['kind'] == 'resync-required')
          throw StateError('live_resync');
        if (result == 'snapshot') {
          _failures = 0;
          _setActive(true);
        }
      }
    } catch (_) {
      if (gen == _generation) reconnect();
    } finally {
      _draining = false;
      if (_current && _frames.isNotEmpty) unawaited(_drain());
    }
  }

  Future<bool> sendSamples(List<dynamic> samples) async {
    if (!_active || _scope == null || samples.isEmpty || samples.length > 16)
      return false;
    for (final sample in samples) {
      if (sample is Map && sample['kind'] == 'cursor')
        _pointer = sample['pointer'];
    }
    _sent = DateTime.now();
    return _write({
      'kind': 'motion',
      'scope': _scope,
      'sequence': ++_sequence,
      'sampledAtMs': DateTime.now().millisecondsSinceEpoch,
      'samples': samples,
    });
  }

  void _schedule(int seconds) {
    if (!_current || _retry != null) return;
    _retry = Timer(Duration(seconds: seconds), () {
      _retry = null;
      unawaited(_open());
    });
  }

  void reconnect() {
    _disconnect();
    if (_current) _schedule(1 << (_failures++).clamp(0, 5));
  }

  void _disconnect() {
    _generation++;
    _opening = false;
    _renew?.cancel();
    _renew = null;
    _subscription?.cancel();
    _subscription = null;
    final old = _socket;
    _socket = null;
    if (old != null) unawaited(old.close());
    _lease = '';
    _scope = null;
    _frames.clear();
    _pending = 0;
    _outgoing = 0;
    _writes = Future.value();
    _pointer = null;
    _active = false;
    changed(false);
  }

  void sleep() {
    _awake = false;
    _retry?.cancel();
    _retry = null;
    _disconnect();
  }

  void wake() {
    if (_closed) return;
    _awake = true;
    unawaited(_open());
  }

  void stop() {
    _closed = true;
    _heartbeat?.cancel();
    _heartbeat = null;
    _retry?.cancel();
    _retry = null;
    _disconnect();
  }
}
