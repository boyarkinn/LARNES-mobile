import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:larnes_mobile/core/app_update/app_update_info.dart';
import 'package:larnes_mobile/core/app_update/app_update_service.dart';

enum AppUpdateStatus {
  idle,
  checking,
  available,
  downloading,
  verifying,
  installerReady,
  error,
}

class AppUpdateController extends ChangeNotifier {
  AppUpdateController({AppUpdateService? service})
    : _service = service ?? AppUpdateService();

  final AppUpdateService _service;

  AppUpdateStatus status = AppUpdateStatus.idle;
  AppUpdateInfo? availableUpdate;
  String? localVersionLabel;
  String? errorMessage;
  bool dismissedThisSession = false;
  bool dialogShownThisSession = false;
  double downloadProgress = 0;
  int receivedBytes = 0;
  int? totalBytes;
  CancelToken? _cancelToken;
  String? _verifiedPath;
  int? _verifiedVersion;

  bool get isBusy =>
      status == AppUpdateStatus.downloading ||
      status == AppUpdateStatus.verifying;

  bool get shouldOfferUpdate =>
      availableUpdate != null &&
      !dismissedThisSession &&
      status != AppUpdateStatus.checking;

  bool get shouldShowColdStartDialog =>
      shouldOfferUpdate && !dialogShownThisSession;

  Future<void> checkForUpdate({bool forceNotify = true}) async {
    if (isBusy || status == AppUpdateStatus.checking) return;
    if (!await _service.isAndroidPlatform) {
      return;
    }

    status = AppUpdateStatus.checking;
    errorMessage = null;
    if (forceNotify) {
      notifyListeners();
    }

    try {
      localVersionLabel = await _service.readLocalVersionLabel();
      availableUpdate = await _service.fetchAvailableUpdate();
      status = availableUpdate == null
          ? AppUpdateStatus.idle
          : AppUpdateStatus.available;
    } catch (error) {
      status = AppUpdateStatus.error;
      errorMessage = error.toString();
    }

    notifyListeners();
  }

  void dismissForSession() {
    dismissedThisSession = true;
    dialogShownThisSession = true;
    notifyListeners();
  }

  void markDialogShown() {
    dialogShownThisSession = true;
  }

  Future<void> downloadAndInstall({
    required void Function(double progress) onProgress,
    required void Function(String message) onError,
  }) async {
    final update = availableUpdate;
    if (update == null || isBusy) {
      return;
    }

    status = AppUpdateStatus.downloading;
    downloadProgress = 0;
    receivedBytes = 0;
    totalBytes = null;
    errorMessage = null;
    final cancel = _cancelToken = CancelToken();
    notifyListeners();

    try {
      final filePath =
          _verifiedVersion == update.versionCode && _verifiedPath != null
          ? _verifiedPath!
          : await _service.downloadApk(
              update: update,
              cancelToken: cancel,
              onProgress: (received, total) {
                receivedBytes = received;
                totalBytes = total != null && total > 0 ? total : null;
                if (total != null && total > 0) {
                  downloadProgress = (received / total).clamp(0.0, 1.0);
                  onProgress(downloadProgress);
                }
                notifyListeners();
              },
            );
      if (cancel.isCancelled) throw cancel.cancelError!;
      status = AppUpdateStatus.verifying;
      notifyListeners();
      await _service.verifySha256(
        filePath: filePath,
        expectedSha256: update.sha256,
      );
      if (cancel.isCancelled) throw cancel.cancelError!;
      _verifiedPath = filePath;
      _verifiedVersion = update.versionCode;
      await _service.openInstaller(filePath);
      status = AppUpdateStatus.installerReady;
      notifyListeners();
    } on AppUpdateVerificationException {
      _verifiedPath = null;
      _verifiedVersion = null;
      status = AppUpdateStatus.error;
      errorMessage = 'checksum';
      onError('checksum');
      notifyListeners();
    } on AppUpdateInstallException catch (error) {
      status = AppUpdateStatus.error;
      errorMessage = error.message;
      onError(error.message);
      notifyListeners();
    } catch (error) {
      if (error is DioException && CancelToken.isCancel(error)) {
        status = AppUpdateStatus.available;
        notifyListeners();
        return;
      }
      status = AppUpdateStatus.error;
      errorMessage = error.toString();
      onError(error.toString());
      notifyListeners();
    } finally {
      _cancelToken = null;
    }
  }

  void cancelDownload() => _cancelToken?.cancel();
}
