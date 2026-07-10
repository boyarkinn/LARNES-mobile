/// Bottom nav visibility and shell tab indices for admin zone.
class AdminNavigation {
  const AdminNavigation._();

  /// Account branch is declared first in [StatefulShellRoute].
  static const accountTabIndex = 0;
  static const trainersTabIndex = 1;

  static bool showsBottomNav(String location) {
    final path = Uri.tryParse(location)?.path ?? location;
    final segments = path.split('/').where((segment) => segment.isNotEmpty).toList();
    if (segments.isEmpty || segments.first != 'admin') {
      return false;
    }
    if (segments.length >= 3 && segments[1] == 'trainers') {
      return false;
    }
    return true;
  }
}
