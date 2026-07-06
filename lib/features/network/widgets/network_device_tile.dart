import 'package:flutter/material.dart';
import 'package:larnes_mobile/features/network/models/network_device.dart';
import 'package:larnes_mobile/features/network/utils/network_device_labels.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

class NetworkDeviceTile extends StatelessWidget {
  const NetworkDeviceTile({super.key, required this.device});

  final NetworkDevice device;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final statusLabel = device.isOnline ? l10n.networkDeviceOnline : l10n.networkDeviceOffline;
    final statusColor = device.isOnline ? Colors.green.shade700 : theme.colorScheme.outline;

    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        title: Text(networkDeviceTitle(device, l10n)),
        subtitle: Text(networkDevicePlacementLine(device, l10n)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: statusColor),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            statusLabel,
            style: theme.textTheme.labelMedium?.copyWith(color: statusColor),
          ),
        ),
        titleTextStyle: theme.textTheme.titleMedium,
        subtitleTextStyle: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
