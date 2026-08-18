import 'package:flutter/material.dart';
import 'package:larnes_mobile/features/kiosk/models/kiosk_scan_result.dart';
import 'package:larnes_mobile/features/kiosk/widgets/kiosk_child_bound_view.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

/// Result screen after a successful classroom QR scan (v1 — no program player).
class KioskScanResultView extends StatelessWidget {
  const KioskScanResultView({
    super.key,
    required this.result,
  });

  final KioskScanResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isPlay = result.outcome == KioskScanOutcome.play;

    if (!isPlay) {
      return KioskChildBoundView(result: result);
    }

    return Column(
      children: [
        Icon(
          Icons.check_circle_outline,
          size: 64,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Text(
          result.childDisplayName,
          style: theme.textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          l10n.kioskResultProgramAssigned,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
