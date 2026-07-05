import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:larnes_mobile/features/parent/navigation/parent_navigation.dart';

/// Navigation helpers for `/parent/:childId/*` inside the children shell branch.
class ParentChildRoutes {
  const ParentChildRoutes._();

  static StatefulNavigationShellState? _shell(BuildContext context) {
    return StatefulNavigationShell.maybeOf(context);
  }

  static void _ensureChildrenBranch(BuildContext context) {
    final shell = _shell(context);
    if (shell != null && shell.currentIndex != ParentNavigation.childrenTabIndex) {
      shell.goBranch(ParentNavigation.childrenTabIndex, initialLocation: false);
    }
  }

  /// Opens a child from the picker (`/parent` → `/parent/:childId`).
  static Future<T?> openChild<T>(BuildContext context, String childId) {
    _ensureChildrenBranch(context);
    return context.push<T>('/parent/$childId');
  }

  /// Pushes `/parent/:childId/:segment` (absolute — relative `./` breaks when shell URI drifts).
  static Future<T?> pushForChild<T>(
    BuildContext context, {
    required String childId,
    required String segment,
    Object? extra,
  }) {
    _ensureChildrenBranch(context);
    final path = segment.isEmpty ? '/parent/$childId' : '/parent/$childId/$segment';
    return context.push<T>(path, extra: extra);
  }
}
