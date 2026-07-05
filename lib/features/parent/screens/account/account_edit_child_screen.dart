import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Legacy route `/parent/account/children/:childId/edit` → canonical profile.
class AccountEditChildScreen extends StatelessWidget {
  const AccountEditChildScreen({super.key, required this.childId});

  final String childId;

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        context.go('/parent/$childId/profile?from=account');
      }
    });
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
