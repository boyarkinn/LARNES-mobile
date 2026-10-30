import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:larnes_mobile/core/api/kiosk_api.dart';
import 'package:larnes_mobile/core/auth/child_session_token_storage.dart';
import 'package:larnes_mobile/features/messenger/messenger_room.dart';
import 'package:larnes_mobile/features/kiosk/api/kiosk_session_api.dart';
import 'package:larnes_mobile/features/kiosk/models/kiosk_device_command.dart'
    show
        KioskDeviceCommand,
        KioskDeviceCommandKind,
        kioskDeviceCommandClearsChildSession,
        kioskDeviceCommandKindToApiValue;
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
  int? _pendingAck;
  int? _appliedPlayTrainerSeq;
  int _trainerReloadToken = 0;
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
  String? get activeProgramId => _scanResult?.programId;
  int get trainerReloadToken => _trainerReloadToken;

  bool get classroomCallOn =>
      _deviceContext.lesson?.classroomCallEnabled == true &&
      _deviceContext.activeChild != null;

  bool get lessonWorkspaceOn {
    final lesson = _deviceContext.lesson;
    final child = _deviceContext.activeChild;
    if (lesson == null || child == null) return false;
    return lesson.workspaceFormat == 'board' &&
        child.lessonSessionId == lesson.lessonSessionId &&
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

  void exitTrainer() {
    if (_mode != KioskSessionMode.trainer) {
      return;
    }

    _exitRuntimePlayer();
  }

  void exitProgram() {
    if (_mode != KioskSessionMode.play) {
      return;
    }

    _exitRuntimePlayer();
  }

  void _exitRuntimePlayer() {
    if (_scanResult != null) {
      _mode = KioskSessionMode.result;
    } else {
      _mode = resolveInitialModeFromLesson(_deviceContext.lesson);
    }
    notifyListeners();
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

      if (_mode == KioskSessionMode.play &&
          (result.programId == null || result.programId!.isEmpty)) {
        _mode = KioskSessionMode.result;
        _scanError = 'Missing programId';
      }

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
    if (_disposed || _paused || _syncInFlight || _leaving) {
      return;
    }

    _syncInFlight = true;
    final generation = _generation;
    var ackAlreadySent = false;
    try {
      final payload = await _kioskApi.pollCommands(since: _since);
      if (!_current(generation)) return;
      if (_deviceContext.lesson?.workspaceFormat == 'board') {
        final device = await _kioskApi.getDeviceMe();
        if (!_current(generation)) return;
        await _reconcileBoardDevice(device, generation);
        if (!_current(generation)) return;
        await _kioskApi.heartbeat(ackSeq: payload.commandSeq);
        _since = payload.commandSeq;
        return;
      }
      var commandProcessed = false;

      if (payload.commands.isNotEmpty) {
        final latest = payload.commands.last;
        final previousMode = _mode;
        commandProcessed = true;

        if (latest.command == KioskDeviceCommandKind.playTrainer) {
          final started = await _activatePlayTrainer(payload.commandSeq);
          commandProcessed = started;
          ackAlreadySent = started;
        } else if (kioskQrScanFrozen &&
            latest.command == KioskDeviceCommandKind.openScan) {
          await _kioskApi.heartbeat(ackSeq: payload.commandSeq);
          if (!_current(generation)) return;
          ackAlreadySent = true;
          _since = payload.commandSeq;
          if (_scanResult == null) {
            await _reconcileTeacherAssignedChild(force: true);
          }
        } else if (await _tryApplySupersededResetGuard(
          latest,
          payload.commandSeq,
        )) {
          commandProcessed = true;
          ackAlreadySent = true;
          _restartSyncTimer();
          notifyListeners();
        } else {
          final nextMode = modeFromCommand(latest.command);

          await _kioskApi.heartbeat(ackSeq: payload.commandSeq);
          if (!_current(generation)) return;
          ackAlreadySent = true;
          _since = payload.commandSeq;
          _appliedPlayTrainerSeq = null;

          await _kioskApi.childLogout();
          if (!_current(generation)) return;
          await _childSessionTokenStorage.clearToken();
          await MessengerRooms.clear();
          if (!_current(generation)) return;

          if (nextMode != previousMode) {
            _scanError = null;
            _scanErrorCode = null;
          }

          _scanResult = null;
          _mode = nextMode;
          _restartSyncTimer();
          notifyListeners();
        }
      } else if (payload.commandSeq > _since) {
        _since = payload.commandSeq;
      }

      if (!commandProcessed) {
        if (await _reconcileLessonEndedDuringRuntime()) {
          // Lesson ended while child was in program or trainer player.
        } else if ((_mode == KioskSessionMode.scan ||
                _mode == KioskSessionMode.idle) &&
            await _reconcileTeacherAssignedChild()) {
          // Teacher assigned a child while the tablet was idle or waiting for QR.
        } else if (_mode != KioskSessionMode.play &&
            _mode != KioskSessionMode.trainer) {
          final skipRefreshInResult =
              _mode == KioskSessionMode.result && _scanResult != null;
          if (skipRefreshInResult) {
            ackAlreadySent = await _reconcilePendingPlayTrainerFromDevice();
          } else {
            ackAlreadySent = await _refreshDeviceContextAndReconcileMode(
              refresh:
                  _mode != KioskSessionMode.scan &&
                  _mode != KioskSessionMode.idle,
            );
          }
        }
      }

      if (!ackAlreadySent) {
        await _kioskApi.heartbeat(ackSeq: _pendingAck);
      }
      _pendingAck = null;
    } on KioskApiException catch (error) {
      if (_current(generation) && error.statusCode == 401) {
        _onDeviceUnauthorized();
      }
    } catch (_) {
      // retry on next tick
    } finally {
      _syncInFlight = false;
    }
  }

  Future<bool> _activatePlayTrainer(int commandSeq) async {
    // Assignment and the first exercise may arrive in the same poll, before the
    // idle-screen reconciliation has restored the child's bearer.
    if (!lessonWorkspaceOn && _scanResult == null) {
      await _reconcileTeacherAssignedChild(workspaceOnly: true);
    }
    if (lessonWorkspaceOn) {
      await _kioskApi.heartbeat(ackSeq: commandSeq);
      _since = commandSeq;
      return true;
    }
    if (_deviceContext.lesson?.workspaceFormat == 'board') return false;
    if (classroomCallOn) {
      return false;
    }

    if (_mode == KioskSessionMode.trainer &&
        _appliedPlayTrainerSeq == commandSeq) {
      await _kioskApi.heartbeat(ackSeq: commandSeq);
      _since = commandSeq;
      return true;
    }

    await _kioskApi.heartbeat(ackSeq: commandSeq);
    _since = commandSeq;
    _appliedPlayTrainerSeq = commandSeq;
    _trainerReloadToken += 1;
    _mode = KioskSessionMode.trainer;
    _scanError = null;
    _scanErrorCode = null;
    _restartSyncTimer();
    notifyListeners();
    return true;
  }

  /// Poll may return a reset command that the server already superseded (child
  /// bound, trainer queued). Re-fetch before logout to avoid wiping runtime.
  Future<bool> _tryApplySupersededResetGuard(
    KioskDeviceCommand command,
    int commandSeq,
  ) async {
    if (!kioskDeviceCommandClearsChildSession(command.command)) {
      return false;
    }

    final device = await _kioskApi.getDeviceMe();
    _rememberDevice(device);

    final lesson = device.lesson;
    final pending = lesson?.pendingCommand;
    final commandName = kioskDeviceCommandKindToApiValue(command.command);

    if (lesson == null ||
        pending == commandName ||
        (pending == null && device.activeChild == null)) {
      return false;
    }

    if (pending == 'play_trainer') {
      return _activatePlayTrainer(lesson.commandSeq);
    }

    await _kioskApi.heartbeat(ackSeq: commandSeq);
    _since = commandSeq;
    return true;
  }

  Future<bool> _reconcilePendingPlayTrainerFromDevice() async {
    final generation = _generation;
    final device = await _kioskApi.getDeviceMe();
    if (!_current(generation)) return false;
    _rememberDevice(device);

    final lesson = device.lesson;
    if (lesson != null && lesson.pendingCommand == 'play_trainer') {
      if (lessonWorkspaceOn || classroomCallOn) {
        return false;
      }

      if (_mode == KioskSessionMode.trainer &&
          lesson.commandSeq <= _since &&
          _appliedPlayTrainerSeq == lesson.commandSeq) {
        await _kioskApi.heartbeat(ackSeq: lesson.commandSeq);
        return true;
      }

      if (lesson.commandSeq > _since || _mode != KioskSessionMode.trainer) {
        return _activatePlayTrainer(lesson.commandSeq);
      }
    }

    return false;
  }

  Future<bool> _reconcileLessonEndedDuringRuntime() async {
    if (_mode != KioskSessionMode.play && _mode != KioskSessionMode.trainer) {
      return false;
    }

    final generation = _generation;
    final device = await _kioskApi.getDeviceMe();
    if (!_current(generation)) return false;
    _rememberDevice(device);

    if (device.lesson != null) {
      return false;
    }

    await _kioskApi.childLogout();
    await _childSessionTokenStorage.clearToken();
    await MessengerRooms.clear();
    _scanResult = null;
    _scanError = null;
    _scanErrorCode = null;
    _mode = KioskSessionMode.idle;
    _restartSyncTimer();
    notifyListeners();
    return true;
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
    _appliedPlayTrainerSeq = null;
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

  Future<bool> _reconcileTeacherAssignedChild({
    bool workspaceOnly = false,
    bool force = false,
  }) async {
    if (!force &&
        !workspaceOnly &&
        ((_mode != KioskSessionMode.scan && _mode != KioskSessionMode.idle) ||
            _scanResult != null)) {
      return false;
    }

    final generation = _generation;
    final device = await _kioskApi.getDeviceMe();
    if (!_current(generation)) return false;
    if (device.lesson?.workspaceFormat == 'board') {
      return _reconcileBoardDevice(device, generation);
    }
    _rememberDevice(device);

    final activeChild = device.activeChild;
    final lesson = device.lesson;
    if (activeChild == null || lesson == null) {
      return false;
    }
    if (workspaceOnly && lesson.workspaceFormat != 'board') return false;
    if (lesson.workspaceFormat == 'board' &&
        activeChild.lessonSessionId != lesson.lessonSessionId) {
      return false;
    }

    if (!kioskQrScanFrozen &&
        (lesson.pendingCommand == 'open_scan' ||
            lesson.pendingCommand == 'reset_child')) {
      return false;
    }

    if (lesson.status != 'idle_child' &&
        lesson.status != 'no_program' &&
        lesson.status != 'child_active') {
      return false;
    }

    try {
      final resumed = await _kioskApi.resumeChildSession();
      if (!_current(generation)) return false;
      await _childSessionTokenStorage.writeToken(resumed.childSessionToken);
      if (!_current(generation)) return false;
      _scanResult = resumed;
      _restoredLessonId = lesson.lessonSessionId;
      _scanError = null;
      _scanErrorCode = null;
      _mode = lesson.workspaceFormat == 'board'
          ? KioskSessionMode.result
          : modeFromScanOutcome(resumed.outcome);

      if (_mode == KioskSessionMode.play &&
          (resumed.programId == null || resumed.programId!.isEmpty)) {
        _mode = KioskSessionMode.result;
        _scanError = 'Missing programId';
      }

      _restartSyncTimer();
      notifyListeners();
      return true;
    } on KioskApiException catch (error) {
      if (error.statusCode == 401) {
        _onDeviceUnauthorized();
      }
      return false;
    }
  }

  Future<bool> _refreshDeviceContextAndReconcileMode({
    bool refresh = true,
  }) async {
    final generation = _generation;
    final device = refresh ? await _kioskApi.getDeviceMe() : _deviceContext;
    if (!_current(generation)) return false;
    final previousLessonId = _deviceContext.lesson?.lessonSessionId;
    _rememberDevice(device);

    final lesson = device.lesson;
    if (lesson != null && lesson.pendingCommand == 'play_trainer') {
      if (lessonWorkspaceOn ||
          (lesson.classroomCallEnabled && device.activeChild != null)) {
        return false;
      }

      if (_mode == KioskSessionMode.trainer &&
          lesson.commandSeq <= _since &&
          _appliedPlayTrainerSeq == lesson.commandSeq) {
        await _kioskApi.heartbeat(ackSeq: lesson.commandSeq);
        return true;
      }

      if (lesson.commandSeq > _since || _mode != KioskSessionMode.trainer) {
        return _activatePlayTrainer(lesson.commandSeq);
      }
    }

    if (lesson != null &&
        lesson.commandSeq > _since &&
        lesson.pendingCommand == null) {
      _since = lesson.commandSeq;
    }

    final resolved = resolveInitialModeFromLesson(lesson);
    if (resolved == _mode) {
      if (device.lesson?.lessonSessionId != previousLessonId) {
        notifyListeners();
      }
      return false;
    }

    if (resolved == KioskSessionMode.trainer) {
      _trainerReloadToken += 1;
      _mode = KioskSessionMode.trainer;
      _restartSyncTimer();
      notifyListeners();
      return false;
    }

    if (resolved == KioskSessionMode.idle) {
      await _kioskApi.childLogout();
      await _childSessionTokenStorage.clearToken();
      await MessengerRooms.clear();
      _scanResult = null;
      _scanError = null;
      _scanErrorCode = null;
    } else if (resolved == KioskSessionMode.scan && _scanResult == null) {
      _scanError = null;
      _scanErrorCode = null;
      _scanResult = null;
    }

    _mode = resolved;
    notifyListeners();
    return false;
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
