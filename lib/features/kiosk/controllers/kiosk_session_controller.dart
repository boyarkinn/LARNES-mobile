import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:larnes_mobile/core/api/kiosk_api.dart';
import 'package:larnes_mobile/core/auth/child_session_token_storage.dart';
import 'package:larnes_mobile/features/kiosk/api/kiosk_session_api.dart';
import 'package:larnes_mobile/features/kiosk/models/kiosk_device_command.dart';
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
  })  : _kioskApi = kioskApi,
        _childSessionTokenStorage = childSessionTokenStorage,
        _deviceContext = deviceContext,
        _onDeviceUnauthorized = onDeviceUnauthorized,
        _syncInterval = syncInterval,
        _scanResult = initialScanResult,
        _mode = initialMode ??
            resolveInitialModeFromLesson(deviceContext.lesson),
        _since = initialCommandSeq ??
            resolveInitialCommandSeq(deviceContext.lesson);

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
  int _trainerReloadToken = 0;
  Timer? _timer;
  bool _disposed = false;
  bool _paused = false;
  bool _syncInFlight = false;

  KioskDeviceContext get deviceContext => _deviceContext;
  KioskSessionMode get mode => _mode;
  KioskScanResult? get scanResult => _scanResult;
  String? get scanError => _scanError;
  String? get scanErrorCode => _scanErrorCode;
  String? get activeProgramId => _scanResult?.programId;
  int get trainerReloadToken => _trainerReloadToken;

  Duration get _effectiveSyncInterval {
    if (_mode == KioskSessionMode.result ||
        _mode == KioskSessionMode.scan ||
        _scanResult != null) {
      return kioskActiveChildSyncInterval;
    }
    return _syncInterval;
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
    try {
      final result = await _kioskApi.scan(token: token);
      await _childSessionTokenStorage.writeToken(result.childSessionToken);
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
    if (_disposed || _paused || _syncInFlight) {
      return;
    }

    _syncInFlight = true;
    var ackAlreadySent = false;
    try {
      final payload = await _kioskApi.pollCommands(since: _since);
      var commandProcessed = false;

      if (payload.commands.isNotEmpty) {
        final latest = payload.commands.last;
        final previousMode = _mode;
        commandProcessed = true;

        if (latest.command == KioskDeviceCommandKind.playTrainer) {
          commandProcessed = true;
          await _activatePlayTrainer(payload.commandSeq);
          ackAlreadySent = true;
        } else {
          final nextMode = modeFromCommand(latest.command);

          await _kioskApi.heartbeat(ackSeq: payload.commandSeq);
          ackAlreadySent = true;
          _since = payload.commandSeq;

          await _kioskApi.childLogout();
          await _childSessionTokenStorage.clearToken();

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
        } else if (_mode == KioskSessionMode.scan &&
            await _reconcileTeacherAssignedChild()) {
          // Teacher assigned a child while the tablet was waiting for QR.
        } else if (_mode != KioskSessionMode.play &&
            _mode != KioskSessionMode.trainer) {
          final skipRefreshInResult =
              _mode == KioskSessionMode.result && _scanResult != null;
          if (skipRefreshInResult) {
            ackAlreadySent = await _reconcilePendingPlayTrainerFromDevice();
          } else {
            ackAlreadySent = await _refreshDeviceContextAndReconcileMode();
          }
        }
      }

      if (!ackAlreadySent) {
        await _kioskApi.heartbeat(ackSeq: _pendingAck);
      }
      _pendingAck = null;
    } on KioskApiException catch (error) {
      if (error.statusCode == 401) {
        _onDeviceUnauthorized();
      }
    } catch (_) {
      // retry on next tick
    } finally {
      _syncInFlight = false;
    }
  }

  Future<void> _activatePlayTrainer(int commandSeq) async {
    await _kioskApi.heartbeat(ackSeq: commandSeq);
    _since = commandSeq;
    _trainerReloadToken += 1;
    _mode = KioskSessionMode.trainer;
    _scanError = null;
    _scanErrorCode = null;
    _restartSyncTimer();
    notifyListeners();
  }

  Future<bool> _reconcilePendingPlayTrainerFromDevice() async {
    final device = await _kioskApi.getDeviceMe();
    _deviceContext = device;

    final lesson = device.lesson;
    if (lesson != null &&
        lesson.pendingCommand == 'play_trainer' &&
        (lesson.commandSeq > _since || _mode != KioskSessionMode.trainer)) {
      await _activatePlayTrainer(lesson.commandSeq);
      return true;
    }

    return false;
  }

  Future<bool> _reconcileLessonEndedDuringRuntime() async {
    if (_mode != KioskSessionMode.play && _mode != KioskSessionMode.trainer) {
      return false;
    }

    final device = await _kioskApi.getDeviceMe();
    _deviceContext = device;

    if (device.lesson != null) {
      return false;
    }

    await _kioskApi.childLogout();
    await _childSessionTokenStorage.clearToken();
    _scanResult = null;
    _scanError = null;
    _scanErrorCode = null;
    _mode = KioskSessionMode.idle;
    _restartSyncTimer();
    notifyListeners();
    return true;
  }

  Future<bool> _reconcileTeacherAssignedChild() async {
    if (_mode != KioskSessionMode.scan || _scanResult != null) {
      return false;
    }

    final device = await _kioskApi.getDeviceMe();
    _deviceContext = device;

    final activeChild = device.activeChild;
    final lesson = device.lesson;
    if (activeChild == null || lesson == null) {
      return false;
    }

    if (lesson.pendingCommand == 'open_scan' ||
        lesson.pendingCommand == 'reset_child') {
      return false;
    }

    if (lesson.status != 'no_program' && lesson.status != 'child_active') {
      return false;
    }

    try {
      final resumed = await _kioskApi.resumeChildSession();
      await _childSessionTokenStorage.writeToken(resumed.childSessionToken);
      _scanResult = resumed;
      _scanError = null;
      _scanErrorCode = null;
      _mode = modeFromScanOutcome(resumed.outcome);

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

  Future<bool> _refreshDeviceContextAndReconcileMode() async {
    final device = await _kioskApi.getDeviceMe();
    _deviceContext = device;

    final lesson = device.lesson;
    if (lesson != null &&
        lesson.pendingCommand == 'play_trainer' &&
        (lesson.commandSeq > _since || _mode != KioskSessionMode.trainer)) {
      await _activatePlayTrainer(lesson.commandSeq);
      return true;
    }

    if (lesson != null && lesson.commandSeq > _since && lesson.pendingCommand == null) {
      _since = lesson.commandSeq;
    }

    final resolved = resolveInitialModeFromLesson(lesson);
    if (resolved == _mode) {
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
    _disposed = true;
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }
}
