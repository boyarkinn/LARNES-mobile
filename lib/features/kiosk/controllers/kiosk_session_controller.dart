import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:larnes_mobile/core/api/kiosk_api.dart';
import 'package:larnes_mobile/core/auth/child_session_token_storage.dart';
import 'package:larnes_mobile/features/kiosk/api/kiosk_session_api.dart';
import 'package:larnes_mobile/features/kiosk/models/kiosk_device_context.dart';
import 'package:larnes_mobile/features/kiosk/models/kiosk_scan_result.dart';
import 'package:larnes_mobile/features/kiosk/utils/kiosk_initial_mode.dart';

const kioskSyncInterval = Duration(milliseconds: 3000);

class KioskSessionController extends ChangeNotifier {
  KioskSessionController({
    required KioskSessionApi kioskApi,
    required ChildSessionTokenStorage childSessionTokenStorage,
    required KioskDeviceContext deviceContext,
    required VoidCallback onDeviceUnauthorized,
    KioskSessionMode? initialMode,
    int? initialCommandSeq,
    Duration syncInterval = kioskSyncInterval,
  })  : _kioskApi = kioskApi,
        _childSessionTokenStorage = childSessionTokenStorage,
        _deviceContext = deviceContext,
        _onDeviceUnauthorized = onDeviceUnauthorized,
        _syncInterval = syncInterval,
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
    _timer = Timer.periodic(_syncInterval, (_) {
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
    try {
      final payload = await _kioskApi.pollCommands(since: _since);
      var commandProcessed = false;

      if (payload.commands.isNotEmpty) {
        final latest = payload.commands.last;
        final nextMode = modeFromCommand(latest.command);
        final previousMode = _mode;

        await _kioskApi.childLogout();
        await _childSessionTokenStorage.clearToken();

        if (nextMode != previousMode) {
          _scanError = null;
          _scanErrorCode = null;
        }

        _scanResult = null;
        _mode = nextMode;
        _since = payload.commandSeq;
        _pendingAck = payload.commandSeq;
        commandProcessed = true;
        notifyListeners();
      } else if (payload.commandSeq > _since) {
        _since = payload.commandSeq;
      }

      if (!commandProcessed &&
          _mode != KioskSessionMode.play &&
          _mode != KioskSessionMode.result) {
        await _refreshDeviceContextAndReconcileMode();
      }

      await _kioskApi.heartbeat(ackSeq: _pendingAck);
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

  Future<void> _refreshDeviceContextAndReconcileMode() async {
    final device = await _kioskApi.getDeviceMe();
    _deviceContext = device;

    final lesson = device.lesson;
    if (lesson != null && lesson.commandSeq > _since) {
      _since = lesson.commandSeq;
    }

    final resolved = resolveInitialModeFromLesson(lesson);
    if (resolved == _mode) {
      return;
    }

    if (resolved == KioskSessionMode.idle) {
      await _kioskApi.childLogout();
      await _childSessionTokenStorage.clearToken();
      _scanResult = null;
      _scanError = null;
      _scanErrorCode = null;
    } else if (resolved == KioskSessionMode.scan) {
      _scanError = null;
      _scanErrorCode = null;
      _scanResult = null;
    }

    _mode = resolved;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }
}
