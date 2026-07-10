/// Maps web home paths from the API to mobile routes.
String mapHomePathToMobile(String webPath) {
  final path = webPath.split('?').first;
  if (path == '/parent/family-setup') {
    return '/parent/family-setup';
  }
  if (path == '/parent/family-join-dedup' || path.startsWith('/parent/family-join-dedup')) {
    return '/parent/family-join-dedup';
  }
  if (path == '/parent' || path.startsWith('/parent/')) {
    return '/parent';
  }
  if (path == '/network' || path.startsWith('/network/')) {
    return '/network';
  }
  if (path == '/admin' || path.startsWith('/admin/')) {
    return '/admin';
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
    case 'admin':
      return '/admin';
    default:
      return '/home';
  }
}

bool isAdminAccount(String? accountType) => accountType == 'admin';

bool isAdminRoute(String path) => path == '/admin' || path.startsWith('/admin/');

bool isParentAccount(String? accountType) => accountType == 'parent';

bool isNetworkPanelAccount(String? accountType) =>
    accountType == 'network_owner' || accountType == 'staff';

bool isNetworkRoute(String path) => path == '/network' || path.startsWith('/network/');

bool isKioskEnrollRoute(String path) => path == '/kiosk/enroll';

bool isKioskRoute(String path) => path == '/kiosk' || path.startsWith('/kiosk/');

bool isFamilySetupRoute(String path) =>
    path == '/parent/family-setup' || path.startsWith('/parent/family-setup');

bool isFamilyJoinDedupRoute(String path) {
  final base = path.split('?').first;
  return base == '/parent/family-join-dedup' || base.startsWith('/parent/family-join-dedup');
}

bool isFamilyInviteRoute(String path) {
  final base = path.split('?').first;
  return base == '/invite/family-join-request' ||
      base == '/invite/family-guardian' ||
      base.startsWith('/invite/family-join-request') ||
      base.startsWith('/invite/family-guardian');
}

bool isAuthRoute(String path) =>
    path == '/login' ||
    path == '/splash' ||
    path.startsWith('/register') ||
    path == '/password-reset' ||
    path.startsWith('/password-reset/');

bool isParentRoute(String path) => path == '/parent' || path.startsWith('/parent/');

bool isParentAccountRoute(String path) {
  final base = path.split('?').first;
  return base == '/parent/account' || base.startsWith('/parent/account/');
}

/// Дети, профили, ДЗ — gate до ответа «семья уже в LARNES?».
bool isParentChildrenRoute(String path) {
  if (!isParentRoute(path)) {
    return false;
  }
  if (isParentAccountRoute(path) ||
      isFamilySetupRoute(path) ||
      isFamilyJoinDedupRoute(path)) {
    return false;
  }
  return true;
}

bool parentNeedsFamilySetup(String? accountType, bool? familySetupComplete) =>
    isParentAccount(accountType) && familySetupComplete != true;

/// Redirect target for [GoRouter], or `null` when navigation may proceed.
String? resolveAppRedirect({
  required bool isLoading,
  required bool isAuthenticated,
  required String path,
  required String? accountType,
  bool hasDeviceToken = false,
  bool? familySetupComplete,
}) {
  if (isKioskEnrollRoute(path)) {
    if (hasDeviceToken) {
      return '/kiosk';
    }
    if (!isLoading && !isAuthenticated) {
      return '/login';
    }
    if (isAuthenticated && !isNetworkPanelAccount(accountType)) {
      return '/home';
    }
    return null;
  }

  if (isKioskRoute(path)) {
    if (!hasDeviceToken) {
      return '/kiosk/enroll';
    }
    return null;
  }

  if (!isLoading &&
      !isAuthenticated &&
      !isAuthRoute(path) &&
      !isFamilyInviteRoute(path)) {
    return '/login';
  }

  if (isAuthenticated && isParentRoute(path) && !isParentAccount(accountType)) {
    return defaultMobileHomeForAccountType(accountType);
  }

  if (isAuthenticated && isAdminRoute(path) && !isAdminAccount(accountType)) {
    return defaultMobileHomeForAccountType(accountType);
  }

  if (isAuthenticated &&
      isNetworkRoute(path) &&
      !isNetworkPanelAccount(accountType)) {
    return defaultMobileHomeForAccountType(accountType);
  }

  if (isAuthenticated && isAdminAccount(accountType) && path == '/home') {
    return '/admin';
  }

  if (isAuthenticated && isParentAccount(accountType)) {
    if (parentNeedsFamilySetup(accountType, familySetupComplete)) {
      if (isParentChildrenRoute(path)) {
        return '/parent/family-setup';
      }
    } else if (isFamilySetupRoute(path)) {
      return '/parent';
    }
  }

  if (isAuthenticated && (path == '/login' || path == '/splash')) {
    return resolveAuthenticatedHome(
      accountType: accountType,
      familySetupComplete: familySetupComplete,
    );
  }

  return null;
}

String resolveAuthenticatedHome({
  required String? accountType,
  bool? familySetupComplete,
}) {
  if (isParentAccount(accountType) && familySetupComplete != true) {
    return '/parent/family-setup';
  }
  return defaultMobileHomeForAccountType(accountType);
}

/// Явный переход на gate из children-зоны.
String resolveParentChildrenDestination({required bool? familySetupComplete}) {
  if (familySetupComplete != true) {
    return '/parent/family-setup';
  }
  return '/parent';
}

/// После login / register / password-reset: gate для parent, иначе homePath или redirect.
String resolvePostAuthDestination({
  required String? accountType,
  required String homePath,
  bool? familySetupComplete,
  String? redirectPath,
}) {
  if (isParentAccount(accountType) && familySetupComplete != true) {
    return '/parent/family-setup';
  }

  final redirect = redirectPath?.trim();
  if (redirect != null && redirect.isNotEmpty) {
    return redirect;
  }

  return mapHomePathToMobile(homePath);
}

/// Post-bootstrap navigation from `/splash`.
String resolveSplashDestination({
  required bool hasDeviceToken,
  required bool isAuthenticated,
  required String? accountType,
  bool? familySetupComplete,
}) {
  if (hasDeviceToken) {
    return '/kiosk';
  }
  if (isAuthenticated) {
    return resolveAuthenticatedHome(
      accountType: accountType,
      familySetupComplete: familySetupComplete,
    );
  }
  return '/login';
}
