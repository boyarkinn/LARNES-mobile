import 'package:flutter/foundation.dart';
import 'package:larnes_mobile/core/app_update/app_update_info.dart';
import 'package:larnes_mobile/core/app_update/app_update_service.dart';

enum AppUpdateStatus {
  idle,
  checking,
  available,
  downloading,
  error,
}

class AppUpdateController extends ChangeNotifier {
  AppUpdateController({AppUpdateService? service}) : _service = service ?? AppUpdateService();

  final AppUpdateService _service;

  AppUpdateStatus status = AppUpdateStatus.idle;
  AppUpdateInfo? availableUpdate;
  String? localVersionLabel;
  String? errorMessage;
  bool dismissedThisSession = false;
  bool dialogShownThisSession = false;
  double downloadProgress = 0;

  bool get shouldOfferUpdate =>
      status == AppUpdateStatus.available && availableUpdate != null && !dismissedThisSession;

  bool get shouldShowColdStartDialog => shouldOfferUpdate && !dialogShownThisSession;

  Future<void> checkForUpdate({bool forceNotify = true}) async {
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
      status = availableUpdate == null ? AppUpdateStatus.idle : AppUpdateStatus.available;
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
    if (update == null) {
      return;
    }

    status = AppUpdateStatus.downloading;
    downloadProgress = 0;
    notifyListeners();

    try {
      final filePath = await _service.downloadApk(
        update: update,
        onProgress: (received, total) {
          if (total != null && total > 0) {
            downloadProgress = received / total;
            onProgress(downloadProgress);
          }
        },
      );
      await _service.verifySha256(filePath: filePath, expectedSha256: update.sha256);
      await _service.openInstaller(filePath);
      status = AppUpdateStatus.available;
      notifyListeners();
    } on AppUpdateVerificationException {
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
      status = AppUpdateStatus.error;
      errorMessage = error.toString();
      onError(error.toString());
      notifyListeners();
    }
  }
}
