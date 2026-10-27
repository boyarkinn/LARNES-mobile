import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'native_homework_outbox.dart';

String nativeHomeworkOperationId() {
  final random = Random.secure(),
      bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 15) | 64;
  bytes[8] = (bytes[8] & 63) | 128;
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

/// Local before network. One in-flight command and one coalesced, not-yet-sent successor.
/// The successor references its predecessor, so a late ACK cannot reorder drawings.
class NativeHomeworkWriter {
  NativeHomeworkWriter({
    required this.outbox,
    required this.generation,
    required this.versionId,
    required this.cloudVersionId,
    required this.save,
    required this.waitCloud,
    required this.changed,
    this.retryable,
  }) : _initialPendingVersionId = versionId != cloudVersionId
           ? versionId
           : null;
  final NativeHomeworkOutbox outbox;
  final int generation;
  String? versionId, cloudVersionId;
  final Future<Map<String, dynamic>> Function(Map<String, dynamic>) save;
  final Future<void> Function(String) waitCloud;
  final void Function(bool saving, Object? error) changed;
  final bool Function(Object error)? retryable;
  final String? _initialPendingVersionId;
  Map<String, dynamic>? _active, _queued;
  Future<void> _local = Future.value();
  Future<void>? _running;
  Timer? _retry;
  bool _disposed = false;
  Object? _error;

  Future<void> restore() async {
    final pending = await outbox.pending();
    if (pending.length > 2) throw StateError('outbox_conflict');
    if (pending.length == 2 &&
        pending[0]['expectedVersionId'] == pending[1]['operationId']) {
      final first = pending.removeLast();
      pending.insert(0, first);
    }
    if (pending.length == 2 &&
        pending[1]['expectedVersionId'] != pending[0]['operationId']) {
      throw StateError('outbox_conflict');
    }
    if (pending.any(
      (row) => row['protocol'] != 2 || row['generation'] != generation,
    )) {
      throw StateError('outbox_generation');
    }
    if (pending.isNotEmpty) _active = pending[0];
    if (pending.length == 2) _queued = pending[1];
    _start();
  }

  List<dynamic>? get recoveredWork =>
      (_queued ?? _active)?['elements'] as List<dynamic>?;
  Future<void> enqueue(List<dynamic> elements) {
    final copy = jsonDecode(jsonEncode(elements)) as List<dynamic>;
    final next = _local.then((_) async {
      final command = <String, dynamic>{
        'protocol': 2,
        'operationId': _queued?['operationId'] ?? nativeHomeworkOperationId(),
        'generation': generation,
        'expectedVersionId':
            _queued?['expectedVersionId'] ??
            _active?['operationId'] ??
            versionId,
        'elements': copy,
      };
      await outbox.put(
        command,
      ); // A failed local save must prevent the network write.
      _queued = command;
      changed(true, null);
      _start();
    });
    _local = next.catchError((Object error) {
      _error = error;
      changed(false, error);
    });
    return next;
  }

  void _start() {
    if (_disposed || _running != null || (_active == null && _queued == null)) {
      return;
    }
    _retry?.cancel();
    final run = _pump();
    _running = run;
    unawaited(
      run.whenComplete(() {
        _running = null;
        if (!_disposed &&
            (_active != null || _queued != null) &&
            (_error == null || retryable?.call(_error!) != false)) {
          _retry = Timer(const Duration(seconds: 2), _start);
        }
      }),
    );
  }

  Future<void> _pump() async {
    while (!_disposed && (_active != null || _queued != null)) {
      await _local; // Never claim a successor while its coalesced replacement is being flushed.
      _active ??= _queued;
      if (identical(_active, _queued)) _queued = null;
      final command = _active!, id = command['operationId'] as String;
      try {
        changed(true, null);
        final base = command['expectedVersionId'] as String?;
        // Only a freshly seeded, unpublished base needs a barrier. A replay may
        // already be the current cloud head; its older base need not have an operation row.
        if (base != null &&
            base == _initialPendingVersionId &&
            base != cloudVersionId) {
          await waitCloud(base);
        }
        await save(command);
        await waitCloud(id);
        // Cloud receipt establishes the next CAS fence before removing this local operation.
        versionId = id;
        cloudVersionId = id;
        await outbox.acknowledge(id);
        _active = null;
        _error = null;
      } catch (error) {
        _error = error;
        changed(false, error);
        return;
      }
    }
    if (!_disposed) changed(false, null);
  }

  Future<bool> flush() async {
    await _local;
    _start();
    await _running;
    return _error == null && _active == null && _queued == null;
  }

  void dispose() {
    _disposed = true;
    _retry?.cancel();
  }
}
