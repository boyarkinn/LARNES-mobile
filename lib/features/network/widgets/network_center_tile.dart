import 'package:flutter/material.dart';
import 'package:larnes_mobile/features/network/models/network_center.dart';

class NetworkCenterTile extends StatelessWidget {
  const NetworkCenterTile({super.key, required this.center});

  final NetworkCenter center;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        title: Text(center.name),
        subtitle: center.city == null || center.city!.trim().isEmpty
            ? null
            : Text(center.city!),
        titleTextStyle: theme.textTheme.titleMedium,
        subtitleTextStyle: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
