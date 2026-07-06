/// Maps web home paths from the API to mobile routes.
String mapHomePathToMobile(String webPath) {
  final path = webPath.split('?').first;
  if (path == '/parent' || path.startsWith('/parent/')) {
    return '/parent';
  }
  if (path == '/network' || path.startsWith('/network/')) {
    return '/network';
  }
  return '/home';
}

/// Fallback when API did not return homePath (splash after session restore).
String defaultMobileHomeForAccountType(String? accountType) {
  switch (accountType) {
    case 'parent':
      return '/parent';
    case 'network_owner':
    case 'staff':
      return '/network';
    default:
      return '/home';
  }
}

bool isParentAccount(String? accountType) => accountType == 'parent';

bool isNetworkPanelAccount(String? accountType) =>
    accountType == 'network_owner' || accountType == 'staff';

bool isNetworkRoute(String path) => path == '/network' || path.startsWith('/network/');

bool isAuthRoute(String path) =>
    path == '/login' || path == '/splash' || path.startsWith('/register');

bool isParentRoute(String path) => path == '/parent' || path.startsWith('/parent/');

/// Redirect target for [GoRouter], or `null` when navigation may proceed.
String? resolveAppRedirect({
  required bool isLoading,
  required bool isAuthenticated,
  required String path,
  required String? accountType,
}) {
  if (!isLoading && !isAuthenticated && !isAuthRoute(path)) {
    return '/login';
  }

  if (isAuthenticated && isParentRoute(path) && !isParentAccount(accountType)) {
    return defaultMobileHomeForAccountType(accountType);
  }

  if (isAuthenticated &&
      isNetworkRoute(path) &&
      !isNetworkPanelAccount(accountType)) {
    return '/home';
  }

  if (isAuthenticated && (path == '/login' || path == '/splash')) {
    return defaultMobileHomeForAccountType(accountType);
  }

  return null;
}
