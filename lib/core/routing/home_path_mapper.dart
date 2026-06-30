/// Maps web home paths from the API to mobile routes.
String mapHomePathToMobile(String webPath) {
  final path = webPath.split('?').first;
  if (path == '/parent' || path.startsWith('/parent/')) {
    return '/parent';
  }
  return '/home';
}

bool isParentAccount(String? accountType) => accountType == 'parent';
