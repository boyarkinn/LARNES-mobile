import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:larnes_mobile/app/theme/admin_theme.dart';
import 'package:larnes_mobile/features/admin/navigation/admin_navigation.dart';
import 'package:larnes_mobile/features/admin/widgets/admin_bottom_nav.dart';

class AdminShellScaffold extends StatelessWidget {
  const AdminShellScaffold({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  void _onTabSelected(BuildContext context, int index) {
    if (index == AdminNavigation.trainersTabIndex) {
      if (navigationShell.currentIndex == index) {
        context.go('/admin');
        return;
      }
      navigationShell.goBranch(index, initialLocation: true);
      return;
    }

    navigationShell.goBranch(
      AdminNavigation.accountTabIndex,
      initialLocation: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final showBottomNav = AdminNavigation.showsBottomNav(location);

    return Scaffold(
      backgroundColor: AdminColors.background,
      body: navigationShell,
      bottomNavigationBar: showBottomNav
          ? AdminBottomNav(
              currentIndex: navigationShell.currentIndex,
              onDestinationSelected: (index) => _onTabSelected(context, index),
            )
          : null,
    );
  }
}
