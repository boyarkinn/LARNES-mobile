import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:larnes_mobile/app/theme/parent_text_theme.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';
import 'package:larnes_mobile/core/api/parent_panel_error.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/features/parent/navigation/parent_navigation.dart';
import 'package:larnes_mobile/features/parent/utils/family_setup_guard.dart';
import 'package:larnes_mobile/features/parent/widgets/parent_bottom_nav.dart';

class ParentShellScaffold extends StatelessWidget {
  const ParentShellScaffold({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  void _onTabSelected(BuildContext context, int index) {
    final auth = AuthScope.of(context);
    if (index == ParentNavigation.childrenTabIndex) {
      if (auth.familySetupComplete != true) {
        redirectToFamilySetupIfRequired(context, code: kFamilySetupRequiredCode);
        return;
      }
      if (navigationShell.currentIndex == index) {
        context.go('/parent');
        auth.notifyParentDataChanged();
        return;
      }
      navigationShell.goBranch(index, initialLocation: true);
    } else {
      navigationShell.goBranch(
        ParentNavigation.accountTabIndex,
        initialLocation: true,
      );
    }
    auth.notifyParentDataChanged();
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
