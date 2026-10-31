import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:larnes_mobile/core/api/kiosk_api.dart';
import 'package:larnes_mobile/core/auth/child_session_token_storage.dart';
import 'package:larnes_mobile/features/messenger/messenger_room.dart';
import 'package:larnes_mobile/features/kiosk/api/kiosk_session_api.dart';
import 'package:larnes_mobile/features/kiosk/models/kiosk_device_context.dart';
import 'package:larnes_mobile/features/kiosk/models/kiosk_scan_result.dart';
import 'package:larnes_mobile/features/kiosk/utils/kiosk_initial_mode.dart';

const kioskSyncInterval = Duration(milliseconds: 3000);
const kioskActiveChildSyncInterval = Duration(milliseconds: 1000);

class KioskSessionController extends ChangeNotifier {
  KioskSessionController({
    required KioskSessionApi kioskApi,
    required ChildSessionTokenStorage childSessionTokenStorage,
    required KioskDeviceContext deviceContext,
    required VoidCallback onDeviceUnauthorized,
    KioskSessionMode? initialMode,
    int? initialCommandSeq,
    KioskScanResult? initialScanResult,
    Duration syncInterval = kioskSyncInterval,
  }) : _kioskApi = kioskApi,
       _childSessionTokenStorage = childSessionTokenStorage,
       _deviceContext = deviceContext,
       _onDeviceUnauthorized = onDeviceUnauthorized,
       _syncInterval = syncInterval,
       _scanResult = initialScanResult,
       _restoredLessonId = initialScanResult == null
           ? null
           : deviceContext.lesson?.lessonSessionId,
       _mode =
           initialMode ?? resolveInitialModeFromLesson(deviceContext.lesson),
       _since =
           initialCommandSeq ?? resolveInitialCommandSeq(deviceContext.lesson);

  final KioskSessionApi _kioskApi;
  final ChildSessionTokenStorage _childSessionTokenStorage;
  final VoidCallback _onDeviceUnauthorized;
  final Duration _syncInterval;

  KioskDeviceContext _deviceContext;
  KioskSessionMode _mode;
  KioskScanResult? _scanResult;
  String? _scanError;
  String? _scanErrorCode;

  int _since;
  Timer? _timer;
  bool _disposed = false;
  bool _paused = false;
  bool _syncInFlight = false;
  bool _leaving = false;
  int _generation = 0;
  String? _restoredLessonId;
  bool _current(int generation) => !_disposed && generation == _generation;

  KioskDeviceContext get deviceContext => _deviceContext;
  KioskSessionMode get mode => _mode;
  KioskStandbyKind get standbyKind => resolveKioskStandbyKind(
    hasActiveLesson: _deviceContext.lesson != null,
    hasAssignedChild: _deviceContext.activeChild != null || _scanResult != null,
  );
  KioskScanResult? get scanResult => _scanResult;
  String? get scanError => _scanError;
  String? get scanErrorCode => _scanErrorCode;

  bool get lessonWorkspaceOn {
    final lesson = _deviceContext.lesson;
    final child = _deviceContext.activeChild;
    if (lesson == null || child == null) return false;
    return child.lessonSessionId == lesson.lessonSessionId &&
        _scanResult?.childId == child.childId &&
        _scanResult?.assignment == child.assignment &&
        _restoredLessonId == lesson.lessonSessionId &&
        const {
          'child_active',
          'idle_child',
          'no_program',
        }.contains(lesson.status);
  }

  Duration get _effectiveSyncInterval {
    if (_mode == KioskSessionMode.result ||
        _mode == KioskSessionMode.scan ||
        _scanResult != null) {
      return kioskActiveChildSyncInterval;
    }
    return _syncInterval;
  }

  Future<bool> leaveDesk() async {
    if (_disposed || _leaving) return false;
    final childId = _deviceContext.activeChild?.childId ?? _scanResult?.childId;
    final lessonId = _deviceContext.lesson?.lessonSessionId;
    if (childId == null || lessonId == null) return false;
    _leaving = true;
    final generation = ++_generation;
    try {
      await _kioskApi.leaveDesk(
        childId: childId,
        lessonSessionId: lessonId,
        assignment: _deviceContext.activeChild?.assignment,
      );
    } catch (_) {
      _leaving = false;
      return false;
    }
    if (!_current(generation)) {
      _leaving = false;
      return false;
    }
    _scanResult = null;
    _restoredLessonId = null;
    _scanError = null;
    _scanErrorCode = null;
    _deviceContext = KioskDeviceContext(
      deviceId: _deviceContext.deviceId,
      kind: _deviceContext.kind,
      centerName: _deviceContext.centerName,
      classroomId: _deviceContext.classroomId,
      classroomTitle: _deviceContext.classroomTitle,
      slotLabel: _deviceContext.slotLabel,
      lesson: _deviceContext.lesson,
    );
    _mode = KioskSessionMode.idle;
    notifyListeners();
    try {
      await _childSessionTokenStorage.clearToken();
      await MessengerRooms.clear();
    } catch (_) {
      // The server confirmed release. A cache error must not keep the old pupil
      // mounted; authorization fences the old bearer and polling retries cleanup.
    }
    if (!_current(generation)) {
      _leaving = false;
      return false;
    }
    _leaving = false;
    _restartSyncTimer();
    notifyListeners();
    return true;
  }

  void _rememberDevice(KioskDeviceContext device) {
    final previous = _deviceContext.lesson?.classroomCallEnabled ?? false;
    final previousWorkspace = lessonWorkspaceOn;
    final previousChild = _deviceContext.activeChild?.childId;
    final previousLesson = _deviceContext.lesson?.lessonSessionId;
    final previousAssignment = _deviceContext.activeChild?.assignment;
    _deviceContext = device;
    final next = device.lesson?.classroomCallEnabled ?? false;
    if (!_disposed &&
        (previous != next ||
            previousWorkspace != lessonWorkspaceOn ||
            previousChild != device.activeChild?.childId ||
            previousAssignment != device.activeChild?.assignment ||
            previousLesson != device.lesson?.lessonSessionId)) {
      notifyListeners();
    }
  }

  void updateDeviceContext(KioskDeviceContext deviceContext) {
    _deviceContext = deviceContext;
    notifyListeners();
  }

  void clearScanError() {
    if (_scanError == null && _scanErrorCode == null) {
      return;
    }
    _scanError = null;
    _scanErrorCode = null;
    notifyListeners();
  }

  void setPaused(bool paused) {
    _paused = paused;
  }

  void start() {
    if (_timer != null) {
      return;
    }

    unawaited(_syncSession());
    _restartSyncTimer();
  }

  void _restartSyncTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(_effectiveSyncInterval, (_) {
      unawaited(_syncSession());
    });
  }

  @visibleForTesting
  Future<void> runSyncCycle() => _syncSession();

  Future<void> submitScan(String token) async {
    if (_disposed || _leaving) return;
    final generation = ++_generation;
    try {
      final result = await _kioskApi.scan(token: token);
      if (!_current(generation)) return;
      await _childSessionTokenStorage.writeToken(result.childSessionToken);
      if (!_current(generation)) return;
      _restoredLessonId = _deviceContext.lesson?.lessonSessionId;
      _scanResult = result;
      _scanError = null;
      _scanErrorCode = null;
      _mode = modeFromScanOutcome(result.outcome);

      notifyListeners();
      _restartSyncTimer();
    } on KioskApiException catch (error) {
      if (!_current(generation)) return;
      if (error.statusCode == 401) {
        _onDeviceUnauthorized();
        return;
      }
      _scanErrorCode = error.code;
      _scanError = error.message;
      notifyListeners();
    }
  }

  Future<void> _syncSession() async {
    if (_disposed || _paused || _syncInFlight || _leaving) return;
    _syncInFlight = true;
    final generation = _generation;
    try {
      final payload = await _kioskApi.pollCommands(since: _since);
      if (!_current(generation)) return;
      final device = await _kioskApi.getDeviceMe();
      if (!_current(generation)) return;
      await _reconcileBoardDevice(device, generation);
      if (!_current(generation)) return;
      // Old queued commands are acknowledged, never opened as a separate player.
      await _kioskApi.heartbeat(ackSeq: payload.commandSeq);
      if (_current(generation)) _since = payload.commandSeq;
    } on KioskApiException catch (error) {
      if (_current(generation) && error.statusCode == 401)
        _onDeviceUnauthorized();
    } catch (_) {
      // Retry on the next tick; current assignment is validated before mounting.
    } finally {
      _syncInFlight = false;
    }
  }

  Future<bool> _reconcileBoardDevice(
    KioskDeviceContext device,
    int generation,
  ) async {
    _rememberDevice(device);
    final lesson = device.lesson;
    final child = device.activeChild;
    final assigned =
        lesson != null &&
        child != null &&
        child.lessonSessionId == lesson.lessonSessionId &&
        const {
          'child_active',
          'idle_child',
          'no_program',
        }.contains(lesson.status);
    if (assigned &&
        lessonWorkspaceOn &&
        await _childSessionTokenStorage.readToken() ==
            _scanResult?.childSessionToken &&
        _current(generation)) {
      return true;
    }
    if (!_current(generation)) return false;
    // Remove the old pupil before slow token/cache work; registration is separate.
    _scanResult = null;
    _restoredLessonId = null;
    _scanError = null;
    _scanErrorCode = null;
    _mode = KioskSessionMode.idle;
    notifyListeners();
    await _childSessionTokenStorage.clearToken();
    await MessengerRooms.clear();
    if (!_current(generation) || !assigned) return false;
    final resumed = await _kioskApi.resumeChildSession();
    if (!_current(generation)) return false;
    // Validate the current assignment again after a potentially slow response.
    final latest = await _kioskApi.getDeviceMe();
    if (!_current(generation)) return false;
    _rememberDevice(latest);
    if (latest.lesson?.lessonSessionId != lesson.lessonSessionId ||
        latest.activeChild?.childId != child.childId ||
        latest.activeChild?.assignment != child.assignment ||
        resumed.childId != child.childId ||
        resumed.assignment != child.assignment ||
        !const {
          'child_active',
          'idle_child',
          'no_program',
        }.contains(latest.lesson?.status)) {
      return false;
    }
    await _childSessionTokenStorage.writeToken(resumed.childSessionToken);
    if (!_current(generation)) return false;
    _scanResult = resumed;
    _restoredLessonId = lesson.lessonSessionId;
    _mode = KioskSessionMode.result;
    _restartSyncTimer();
    notifyListeners();
    return true;
  }

  @override
  void dispose() {
    if (_disposed) return;
    _generation++;
    _disposed = true;
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }
}
