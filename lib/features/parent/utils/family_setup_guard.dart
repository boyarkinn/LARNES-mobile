import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:larnes_mobile/core/api/family_setup_api.dart';
import 'package:larnes_mobile/core/api/parent_panel_error.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';

export 'package:larnes_mobile/core/api/parent_panel_error.dart' show isFamilySetupRequiredCode;

/// Зарезервированные сегменты — не id ребёнка; иначе ловим gate как :childId.
const reservedParentChildRouteIds = {'family-setup', 'family-join-dedup', 'children'};

bool isReservedParentChildRouteId(String? childId) =>
    childId != null && reservedParentChildRouteIds.contains(childId);


/// Синхронизирует сессию и ведёт на gate (router guard подхватит повторно).
bool redirectToFamilySetupIfRequired(
  BuildContext context, {
  String? code,
}) {
  if (!isFamilySetupRequiredCode(code)) {
    return false;
  }

  AuthScope.of(context).applyFamilySetup(unsetFamilySetupSnapshot);
  context.go('/parent/family-setup');
  return true;
}
