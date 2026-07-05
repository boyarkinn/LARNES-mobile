/// Bottom nav visibility and shell tab indices for parent zone.
class ParentNavigation {
  const ParentNavigation._();

  /// Account branch is declared first in [StatefulShellRoute] so `/parent/account`
  /// is not captured by the children branch `:childId` route.
  static const accountTabIndex = 0;
  static const childrenTabIndex = 1;

  /// Bar everywhere in parent shell except homework/program players.
  static bool showsBottomNav(String location) {
    final path = Uri.tryParse(location)?.path ?? location;
    final segments = path.split('/').where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty || segments.first != 'parent') {
      return false;
    }
    if (segments.length >= 4) {
      final section = segments[2];
      if (section == 'homework' || section == 'programs') {
        return false;
      }
    }
    return true;
  }
}
