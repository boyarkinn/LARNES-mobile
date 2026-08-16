import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/core/routing/home_path_mapper.dart';

void main() {
  group('kiosk route guards', () {
    test('detects kiosk routes', () {
      expect(isKioskRoute('/kiosk'), isTrue);
      expect(isKioskRoute('/kiosk/enroll'), isTrue);
      expect(isKioskRoute('/kiosk/settings'), isTrue);
      expect(isKioskRoute('/network'), isFalse);
    });

    test('detects kiosk enroll route', () {
      expect(isKioskEnrollRoute('/kiosk/enroll'), isTrue);
      expect(isKioskEnrollRoute('/kiosk'), isFalse);
    });
  });

  group('resolveAppRedirect kiosk', () {
    test('redirects /kiosk without device token to login with from=kiosk', () {
      expect(
        resolveAppRedirect(
          isLoading: false,
          isAuthenticated: true,
          path: '/kiosk',
          accountType: 'network_owner',
          hasDeviceToken: false,
        ),
        kioskLoginRedirect,
      );
    });

    test('allows /kiosk when device token exists', () {
      expect(
        resolveAppRedirect(
          isLoading: false,
          isAuthenticated: false,
          path: '/kiosk',
          accountType: null,
          hasDeviceToken: true,
        ),
        isNull,
      );
    });

    test('redirects enrolled device away from legacy enroll route', () {
      expect(
        resolveAppRedirect(
          isLoading: false,
          isAuthenticated: true,
          path: '/kiosk/enroll',
          accountType: 'network_owner',
          hasDeviceToken: true,
        ),
        '/kiosk',
      );
    });

    test('redirects legacy enroll route to login when no device token', () {
      expect(
        resolveAppRedirect(
          isLoading: false,
          isAuthenticated: false,
          path: '/kiosk/enroll',
          accountType: null,
          hasDeviceToken: false,
        ),
        kioskLoginRedirect,
      );
    });
  });

  group('resolveSplashDestination', () {
    test('prefers kiosk when device token exists', () {
      expect(
        resolveSplashDestination(
          hasDeviceToken: true,
          isAuthenticated: true,
          accountType: 'network_owner',
        ),
        '/kiosk',
      );
    });

    test('falls back to account home without device token', () {
      expect(
        resolveSplashDestination(
          hasDeviceToken: false,
          isAuthenticated: true,
          accountType: 'network_owner',
        ),
        '/network',
      );
    });

    test('sends guest to login', () {
      expect(
        resolveSplashDestination(
          hasDeviceToken: false,
          isAuthenticated: false,
          accountType: null,
        ),
        '/login',
      );
    });
  });
}
