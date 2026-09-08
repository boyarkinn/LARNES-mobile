import 'package:flutter/material.dart';
import 'package:larnes_mobile/core/app_update/app_update_controller.dart';
import 'package:larnes_mobile/core/app_update/app_update_dialog.dart';
import 'package:larnes_mobile/core/app_update/app_update_scope.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

class AppUpdateAccountSection extends StatefulWidget {
  const AppUpdateAccountSection({super.key});

  @override
  State<AppUpdateAccountSection> createState() => _AppUpdateAccountSectionState();
}

class _AppUpdateAccountSectionState extends State<AppUpdateAccountSection> {
  bool _checking = false;

  Future<void> _check(AppUpdateController controller) async {
    setState(() => _checking = true);
    await controller.checkForUpdate();
    if (mounted) {
      setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppUpdateScope.maybeOf(context);
    if (controller == null) {
      return const SizedBox.shrink();
    }

    final l10n = context.l10n;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final update = controller.availableUpdate;
        final versionLabel = controller.localVersionLabel ?? '—';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                l10n.appUpdateInstalledVersion(versionLabel),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            if (update != null && controller.shouldOfferUpdate)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Material(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.appUpdateAvailableTitle,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.appUpdateAvailableMessage(
                            update.versionName,
                            update.versionCode,
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: controller.status == AppUpdateStatus.downloading
                              ? null
                              : () => showAppUpdateDialog(context, controller: controller),
                          child: Text(l10n.appUpdateInstallButton),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: OutlinedButton(
                onPressed: _checking ? null : () => _check(controller),
                child: Text(_checking ? l10n.appUpdateCheckingButton : l10n.appUpdateCheckButton),
              ),
            ),
          ],
        );
      },
    );
  }
}
