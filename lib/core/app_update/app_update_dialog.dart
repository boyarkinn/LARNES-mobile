import 'package:flutter/material.dart';
import 'package:larnes_mobile/core/app_update/app_update_controller.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

Future<void> showAppUpdateDialog(
  BuildContext context, {
  required AppUpdateController controller,
}) {
  final update = controller.availableUpdate;
  if (update == null) {
    return Future.value();
  }

  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      var installing = false;
      return StatefulBuilder(
        builder: (context, setState) {
          final l10n = context.l10n;
          return AlertDialog(
            title: Text(l10n.appUpdateAvailableTitle),
            content: Text(
              l10n.appUpdateAvailableMessage(update.versionName, update.versionCode),
            ),
            actions: [
              TextButton(
                onPressed: installing
                    ? null
                    : () {
                        controller.dismissForSession();
                        Navigator.pop(dialogContext);
                      },
                child: Text(l10n.appUpdateLaterButton),
              ),
              FilledButton(
                onPressed: installing
                    ? null
                    : () async {
                        setState(() => installing = true);
                        await controller.downloadAndInstall(
                          onProgress: (_) {},
                          onError: (message) {
                            if (dialogContext.mounted) {
                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    message == 'checksum'
                                        ? l10n.appUpdateChecksumFailed
                                        : l10n.appUpdateInstallFailed,
                                  ),
                                ),
                              );
                            }
                          },
                        );
                        if (dialogContext.mounted) {
                          setState(() => installing = false);
                        }
                      },
                child: Text(
                  installing ? l10n.appUpdateDownloadingButton : l10n.appUpdateInstallButton,
                ),
              ),
            ],
          );
        },
      );
    },
  );
}
