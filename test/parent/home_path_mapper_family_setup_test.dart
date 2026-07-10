import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/core/routing/home_path_mapper.dart';

void main() {
  group('mapHomePathToMobile', () {
    test('maps parent and network web paths', () {
      expect(mapHomePathToMobile('/parent'), '/parent');
      expect(mapHomePathToMobile('/parent/family-setup'), '/parent/family-setup');
      expect(mapHomePathToMobile('/parent/family-join-dedup'), '/parent/family-join-dedup');
      expect(mapHomePathToMobile('/parent/child-1'), '/parent');
      expect(mapHomePathToMobile('/network'), '/network');
      expect(mapHomePathToMobile('/network/centers'), '/network');
      expect(mapHomePathToMobile('/teacher'), '/home');
    });

    test('strips query string', () {
      expect(mapHomePathToMobile('/network?foo=1'), '/network');
    });
  });

  group('defaultMobileHomeForAccountType', () {
    test('routes panel accounts to mobile homes', () {
      expect(defaultMobileHomeForAccountType('parent'), '/parent');
      expect(defaultMobileHomeForAccountType('network_owner'), '/network');
      expect(defaultMobileHomeForAccountType('staff'), '/network');
      expect(defaultMobileHomeForAccountType('teacher'), '/home');
      expect(defaultMobileHomeForAccountType(null), '/home');
    });
  });

  group('account and route guards', () {
    test('detects network panel accounts', () {
      expect(isNetworkPanelAccount('network_owner'), isTrue);
      expect(isNetworkPanelAccount('staff'), isTrue);
      expect(isNetworkPanelAccount('parent'), isFalse);
      expect(isNetworkPanelAccount('teacher'), isFalse);
    });

    test('detects network routes', () {
      expect(isNetworkRoute('/network'), isTrue);
      expect(isNetworkRoute('/network/centers'), isTrue);
      expect(isNetworkRoute('/parent'), isFalse);
    });

    test('detects family invite routes', () {
      expect(isFamilyInviteRoute('/invite/family-guardian?token=abc'), isTrue);
      expect(isFamilyInviteRoute('/invite/family-join-request'), isTrue);
      expect(isFamilyInviteRoute('/parent/account'), isFalse);
    });
  });

  group('family setup redirect', () {
    test('blocks children routes until setup complete', () {
      expect(
        resolveAppRedirect(
          isLoading: false,
          isAuthenticated: true,
          path: '/parent',
          accountType: 'parent',
          familySetupComplete: false,
        ),
        '/parent/family-setup',
      );
      expect(
        resolveAppRedirect(
          isLoading: false,
          isAuthenticated: true,
          path: '/parent/account',
          accountType: 'parent',
          familySetupComplete: false,
        ),
        isNull,
      );
      expect(
        resolveAppRedirect(
          isLoading: false,
          isAuthenticated: true,
          path: '/parent/family-setup',
          accountType: 'parent',
          familySetupComplete: false,
        ),
        isNull,
      );
      expect(
        resolveAppRedirect(
          isLoading: false,
          isAuthenticated: true,
          path: '/parent/family-join-dedup?token=abc&kind=family-join-request',
          accountType: 'parent',
          familySetupComplete: false,
        ),
        isNull,
      );
    });

    test('allows invite routes without auth', () {
      expect(
        resolveAppRedirect(
          isLoading: false,
          isAuthenticated: false,
          path: '/invite/family-guardian?token=abc',
          accountType: null,
        ),
        isNull,
      );
    });

    test('splash sends incomplete parent to gate', () {
      expect(
        resolveSplashDestination(
          hasDeviceToken: false,
          isAuthenticated: true,
          accountType: 'parent',
          familySetupComplete: false,
        ),
        '/parent/family-setup',
      );
      expect(
        resolveSplashDestination(
          hasDeviceToken: false,
          isAuthenticated: true,
          accountType: 'parent',
          familySetupComplete: null,
        ),
        '/parent/family-setup',
      );
    });

    test('resolvePostAuthDestination sends new parent to gate', () {
      expect(
        resolvePostAuthDestination(
          accountType: 'parent',
          homePath: '/parent',
          familySetupComplete: false,
        ),
        '/parent/family-setup',
      );
      expect(
        resolvePostAuthDestination(
          accountType: 'parent',
          homePath: '/parent',
          familySetupComplete: null,
        ),
        '/parent/family-setup',
      );
      expect(
        resolvePostAuthDestination(
          accountType: 'parent',
          homePath: '/parent/family-setup',
          familySetupComplete: false,
        ),
        '/parent/family-setup',
      );
      expect(
        resolvePostAuthDestination(
          accountType: 'parent',
          homePath: '/parent',
          familySetupComplete: true,
        ),
        '/parent',
      );
      expect(
        resolvePostAuthDestination(
          accountType: 'parent',
          homePath: '/parent',
          familySetupComplete: true,
          redirectPath: '/parent/account',
        ),
        '/parent/account',
      );
      expect(
        resolvePostAuthDestination(
          accountType: 'parent',
          homePath: '/parent',
          familySetupComplete: false,
          redirectPath: '/parent/account',
        ),
        '/parent/family-setup',
      );
    });

    test('null family setup blocks parent shell', () {
      expect(
        resolveAppRedirect(
          isLoading: false,
          isAuthenticated: true,
          path: '/parent',
          accountType: 'parent',
          familySetupComplete: null,
        ),
        '/parent/family-setup',
      );
    });
  });
}
