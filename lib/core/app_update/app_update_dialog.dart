import 'package:flutter/material.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';
import 'package:larnes_mobile/core/app_update/app_update_controller.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

Future<void> showAppUpdateDialog(
  BuildContext context, {
  required AppUpdateController controller,
}) {
  final offered = controller.availableUpdate;
  if (offered == null) return Future.value();
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final l10n = context.l10n;
        final update = controller.availableUpdate ?? offered;
        final ready = controller.status == AppUpdateStatus.installerReady;
        return PopScope(
          canPop: !controller.isBusy,
          child: Dialog(
            backgroundColor: ParentColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(ParentRadii.card),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: CircleAvatar(
                        backgroundColor: ParentColors.shellSoft,
                        foregroundColor: ParentColors.shell,
                        radius: 24,
                        child: Icon(Icons.system_update_rounded, size: 28),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.appUpdateAvailableMessage(
                        update.versionName,
                        update.versionCode,
                      ),
                      style: const TextStyle(
                        fontSize: 22,
                        height: 1.2,
                        fontWeight: FontWeight.w700,
                        color: ParentColors.ink,
                      ),
                    ),
                    if (controller.isBusy ||
                        ready ||
                        controller.status == AppUpdateStatus.error) ...[
                      const SizedBox(height: 20),
                      AppUpdateProgress(controller: controller),
                    ],
                    const SizedBox(height: 24),
                    if (!controller.isBusy)
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: ParentColors.shell,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () => controller.downloadAndInstall(
                          onProgress: (_) {},
                          onError: (_) {},
                        ),
                        icon: Icon(
                          ready
                              ? Icons.install_mobile_rounded
                              : Icons.download_rounded,
                        ),
                        label: Text(
                          ready
                              ? l10n.appUpdateOpenInstaller
                              : l10n.appUpdateInstallButton,
                        ),
                      ),
                    TextButton(
                      onPressed: controller.isBusy
                          ? controller.cancelDownload
                          : () {
                              controller.dismissForSession();
                              Navigator.pop(dialogContext);
                            },
                      child: Text(
                        controller.isBusy
                            ? l10n.appUpdateCancelDownload
                            : l10n.appUpdateLaterButton,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}

/// The account screen and the offer dialog observe the same download owner.
class AppUpdateProgress extends StatelessWidget {
  const AppUpdateProgress({super.key, required this.controller});
  final AppUpdateController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final status = controller.status;
    if (status == AppUpdateStatus.error) {
      return Text(
        controller.errorMessage == 'checksum'
            ? l10n.appUpdateChecksumFailed
            : l10n.appUpdateDownloadFailed,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      );
    }
    if (status == AppUpdateStatus.installerReady) {
      return Text(
        l10n.appUpdateInstallerReady,
        style: const TextStyle(color: ParentColors.inkMuted),
      );
    }
    final downloading = status == AppUpdateStatus.downloading;
    final known = downloading && controller.totalBytes != null;
    final bytes = (controller.receivedBytes / (1024 * 1024)).toStringAsFixed(1);
    final total = controller.totalBytes == null
        ? null
        : (controller.totalBytes! / (1024 * 1024)).toStringAsFixed(1);
    final percent = (controller.downloadProgress * 100).floor();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                downloading
                    ? l10n.appUpdateDownloadingButton
                    : l10n.appUpdateVerifying,
                style: const TextStyle(
                  color: ParentColors.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (known)
              Text(
                '$percent%',
                style: const TextStyle(
                  color: ParentColors.shell,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        LinearProgressIndicator(
          value: known ? controller.downloadProgress : null,
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
          color: ParentColors.shell,
          backgroundColor: ParentColors.shellSoft,
          semanticsLabel: downloading
              ? l10n.appUpdateDownloadingButton
              : l10n.appUpdateVerifying,
        ),
        if (downloading && controller.receivedBytes > 0) ...[
          const SizedBox(height: 8),
          Text(
            l10n.appUpdateDownloadedSize(
              total == null ? bytes : '$bytes / $total',
            ),
            style: const TextStyle(color: ParentColors.inkMuted, fontSize: 13),
          ),
        ],
      ],
    );
  }
}
