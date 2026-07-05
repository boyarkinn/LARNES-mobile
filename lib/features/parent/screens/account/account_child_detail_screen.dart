import 'package:flutter/material.dart';
import 'package:larnes_mobile/features/parent/screens/child_profile_screen.dart';

/// Legacy route `/parent/account/children/:childId` → canonical child profile.
class AccountChildDetailScreen extends StatelessWidget {
  const AccountChildDetailScreen({super.key, required this.childId});

  final String childId;

  @override
  Widget build(BuildContext context) {
    return ChildProfileScreen(
      childId: childId,
      origin: ChildProfileOrigin.account,
    );
  }
}
