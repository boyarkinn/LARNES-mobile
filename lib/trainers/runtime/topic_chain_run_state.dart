import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const topicChainStatePrefix = 'topic-chain-flash:TopicChainFlashTrainer:';

String topicChainUuid() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 15) | 64;
  bytes[8] = (bytes[8] & 63) | 128;
  final hex = bytes
      .map((value) => value.toRadixString(16).padLeft(2, '0'))
      .join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

typedef TopicChainRequest =
    Future<Map<String, dynamic>> Function(Map<String, dynamic> command);

Map<String, dynamic> _clone(Map<String, dynamic> value) =>
    Map<String, dynamic>.from(jsonDecode(jsonEncode(value)) as Map);

/// One authenticated launch, serialized writes and a bounded pending command.
/// The server owns the chain, first answer and revision; this never keys runs by params.
class TopicChainRunController extends ChangeNotifier {
  TopicChainRunController({
    required this.request,
    required this.context,
    required this.ownerId,
    required this.locale,
    this.params,
  });
  final TopicChainRequest request;
  final Map<String, dynamic> context;
  final String ownerId, locale;
  final Map<String, dynamic>? params;
  Map<String, dynamic>? run;
  Map<String, dynamic> state = {};
  Map<String, dynamic>? _pending;
  Future<void>? _inFlight;
  Timer? _timer;
  bool _dirty = false, _disposed = false;
  bool failed = false;
  int generation = 0;

  String get storageKey =>
      'topic-chain-pending:$ownerId:${jsonEncode(context)}';
  bool get ready => run != null;

  Future<void> open() async {
    failed = false;
    try {
      final reply = await request({
        'action': 'open',
        'context': context,
        'uiLocale': locale,
        if (params != null) 'params': params,
      });
      run = Map<String, dynamic>.from(reply['run'] as Map);
      state = _clone(
        Map<String, dynamic>.from(run!['state'] as Map? ?? const {}),
      );
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(storageKey);
      if (raw != null) {
        Map<String, dynamic>? pending;
        try {
          if (raw.length <= 120000) {
            final cached = Map<String, dynamic>.from(jsonDecode(raw) as Map);
            final timestamp = (cached['savedAt'] as num?)?.toInt() ?? 0;
            if (DateTime.now().millisecondsSinceEpoch - timestamp <=
                    const Duration(days: 7).inMilliseconds &&
                cached['command'] is Map) {
              pending = Map<String, dynamic>.from(cached['command'] as Map);
            }
          }
        } catch (_) {
          // Invalid local bytes never replace a server checkpoint.
        }
        if (pending?['runId'] == run!['id'] && pending?['state'] is Map) {
          _pending = pending;
          state = _clone(Map<String, dynamic>.from(pending!['state'] as Map));
          _dirty = true;
          await flush();
        } else {
          await prefs.remove(storageKey);
        }
      }
      if (!_disposed) notifyListeners();
    } catch (_) {
      failed = true;
      if (!_disposed) notifyListeners();
      rethrow;
    }
  }

  void record(Map<String, dynamic> next, {bool immediate = false}) {
    if (_disposed || !ready || jsonEncode(next) == jsonEncode(state)) return;
    final encoded = jsonEncode(next);
    if (utf8.encode(encoded).length > 96 * 1024) {
      throw StateError('topic-chain-state-too-large');
    }
    state = _clone(next);
    _dirty = true;
    _timer?.cancel();
    if (immediate) {
      unawaited(flush().catchError((Object _) {}));
    } else {
      _timer = Timer(const Duration(milliseconds: 150), () {
        unawaited(flush().catchError((Object _) {}));
      });
    }
  }

  Future<void> flush() {
    _timer?.cancel();
    final active = _inFlight;
    if (active != null) return active;
    final operation = _save();
    _inFlight = operation;
    return operation.whenComplete(() => _inFlight = null);
  }

  Future<void> _save() async {
    if (!ready) return;
    try {
      while (_dirty || _pending != null) {
        final target =
            _pending ??
            {
              'action': 'save',
              'context': context,
              'runId': run!['id'],
              'revision': run!['revision'],
              'requestId': topicChainUuid(),
              'state': _clone(state),
            };
        _pending = target;
        _dirty = false;
        final prefs = await SharedPreferences.getInstance();
        if (!await prefs.setString(
          storageKey,
          jsonEncode({
            'savedAt': DateTime.now().millisecondsSinceEpoch,
            'command': target,
          }),
        )) {
          throw StateError('topic-chain-local-save');
        }
        final saved = <String, int>{};
        for (final key in prefs.getKeys().where(
          (key) => key.startsWith('topic-chain-pending:$ownerId:'),
        )) {
          try {
            saved[key] =
                ((jsonDecode(prefs.getString(key)!) as Map)['savedAt'] as num)
                    .toInt();
          } catch (_) {
            saved[key] = 0;
          }
        }
        final ordered = saved.keys.where((key) => key != storageKey).toList()
          ..sort((a, b) => saved[b]!.compareTo(saved[a]!));
        for (var i = 0; i < ordered.length; i++) {
          if (i >= 19 ||
              DateTime.now().millisecondsSinceEpoch - saved[ordered[i]]! >
                  const Duration(days: 7).inMilliseconds) {
            await prefs.remove(ordered[i]);
          }
        }
        final reply = await request(target);
        final incoming = Map<String, dynamic>.from(reply['run'] as Map);
        if (incoming['id'] != run!['id']) {
          throw StateError('topic-chain-wrong-run');
        }
        if (reply['status'] == 'conflict') {
          // Another writer or a lost acknowledgement may already have advanced
          // the run. Adopt the authoritative checkpoint rather than resubmit a
          // different first/retry answer or roll it back.
          run = {...run!, ...incoming};
          state = _clone(Map<String, dynamic>.from(incoming['state'] as Map));
          _dirty = false;
          _pending = null;
          generation++;
          await prefs.remove(storageKey);
          if (!_disposed) notifyListeners();
          break;
        }
        run = {...run!, ...incoming};
        _pending = null;
        await prefs.remove(storageKey);
      }
      failed = false;
    } catch (_) {
      failed = true;
      if (!_disposed) notifyListeners();
      rethrow;
    }
  }

  Future<void> retry() async {
    failed = false;
    if (!ready) return open();
    await flush();
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    // Accepted answers are flushed before continuing. This is a final best
    // effort for non-critical animation/draft checkpoints; no credentials saved.
    if (_dirty) unawaited(flush().catchError((Object _) {}));
    super.dispose();
  }
}
