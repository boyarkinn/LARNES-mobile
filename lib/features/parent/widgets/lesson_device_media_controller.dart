import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:larnes_mobile/features/parent/models/lesson_device_media.dart';

/// A lesson control channel. Its lifetime never owns the board or its WebView.
class LessonDeviceMediaController extends ChangeNotifier {
  LessonDeviceMediaController({
    required this.childId,
    required this.lessonSessionId,
    required this.fetch,
    required this.send,
  });
  final String childId, lessonSessionId;
  final Future<LessonDeviceMedia?> Function() fetch;
  final Future<LessonDeviceMedia?> Function(Map<String, dynamic>) send;
  LessonDeviceMedia? media;
  bool failed = false, _busy = false, _disposed = false;
  Timer? _timer;
  Future<void> _writes = Future.value();
  final Map<String, bool> _pending = {};
  final Map<String, int> _sequence = {};
  bool requested(String device) =>
      _pending[device] ??
      (device == 'audio' ? media?.audio : media?.video) ??
      false;
  bool get needed =>
      !failed &&
      media?.needed == true &&
      (requested('audio') ||
          requested('video') ||
          (media?.receive == true &&
              media?.audio != true &&
              media?.video != true));
  void start() {
    unawaited(refresh());
    _timer ??= Timer.periodic(
      const Duration(seconds: 1),
      (_) => unawaited(refresh()),
    );
  }

  Future<void> refresh() async {
    if (_busy || _disposed) return;
    _busy = true;
    try {
      _apply(await fetch());
    } catch (_) {
      if (!_disposed) {
        failed = true;
        notifyListeners();
      }
    } finally {
      _busy = false;
    }
  }

  void _apply(LessonDeviceMedia? next, {String? assignment}) {
    if (_disposed ||
        next == null ||
        next.childId != childId ||
        next.lessonSessionId != lessonSessionId) {
      return;
    }
    if (assignment != null && media?.assignment != assignment) return;
    if (next.assignment == media?.assignment &&
        next.revision < media!.revision) {
      return;
    }
    if (next.assignment != media?.assignment) {
      _pending.clear();
      _sequence.clear();
    }
    media = next;
    failed = false;
    notifyListeners();
  }

  Future<void> change(String device, bool enabled) {
    final seq = (_sequence[device] ?? 0) + 1;
    _sequence[device] = seq;
    _pending[device] = enabled;
    notifyListeners();
    return _send({'device': device, 'enabled': enabled}).whenComplete(() {
      if (!_disposed && !failed && _sequence[device] == seq) {
        _pending.remove(device);
        notifyListeners();
      }
    });
  }

  Future<void> report({
    bool? joined,
    String? failedDevice,
    String? error,
    LessonDeviceMedia? expected,
  }) => _send({
    'joined': ?joined,
    'failedDevice': ?failedDevice,
    'error': ?error,
  }, expected: expected ?? media);
  Future<void> _send(Map<String, dynamic> body, {LessonDeviceMedia? expected}) {
    final assignment = (expected ?? media)?.assignment;
    final operation = _writes.catchError((_) {}).then((_) async {
      final current = media;
      if (_disposed ||
          current == null ||
          assignment == null ||
          current.assignment != assignment) {
        return;
      }
      if (expected != null && current.revision != expected.revision) return;
      try {
        final next = await send({
          ...body,
          'assignment': assignment,
          'revision': current.revision,
          'childId': childId,
          'lessonSessionId': lessonSessionId,
        });
        if (next == null) {
          if (!_disposed) {
            failed = true;
            notifyListeners();
          }
          return;
        }
        _apply(next, assignment: assignment);
      } catch (_) {
        if (!_disposed) {
          failed = true;
          notifyListeners();
        }
      }
    });
    _writes = operation;
    return operation;
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}
