import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:larnes_mobile/app/theme/parent_text_theme.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/features/parent/navigation/parent_navigation.dart';
import 'package:larnes_mobile/features/parent/widgets/parent_bottom_nav.dart';

class ParentShellScaffold extends StatelessWidget {
  const ParentShellScaffold({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  void _onTabSelected(BuildContext context, int index) {
    if (index == ParentNavigation.childrenTabIndex) {
      if (navigationShell.currentIndex == index) {
        context.go('/parent');
        AuthScope.of(context).notifyParentDataChanged();
        return;
      }
      navigationShell.goBranch(index, initialLocation: true);
    } else {
      navigationShell.goBranch(
        ParentNavigation.accountTabIndex,
        initialLocation: true,
      );
    }
    AuthScope.of(context).notifyParentDataChanged();
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final showBottomNav = ParentNavigation.showsBottomNav(location);

    return Theme(
      data: Theme.of(context).copyWith(textTheme: buildParentTextTheme()),
      child: ParentParchmentBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: navigationShell,
          bottomNavigationBar: showBottomNav
              ? ParentBottomNav(
                  currentIndex: navigationShell.currentIndex,
                  onDestinationSelected: (index) => _onTabSelected(context, index),
                )
              : null,
        ),
      ),
    );
  }
}
