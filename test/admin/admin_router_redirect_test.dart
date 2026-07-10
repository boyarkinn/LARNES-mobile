import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/core/routing/home_path_mapper.dart';

void main() {
  group('mapHomePathToMobile', () {
    test('maps admin web home to mobile admin root', () {
      expect(mapHomePathToMobile('/admin'), '/admin');
      expect(mapHomePathToMobile('/admin/dev'), '/admin');
      expect(mapHomePathToMobile('/admin/account'), '/admin');
    });
  });

  group('defaultMobileHomeForAccountType', () {
    test('returns admin root for admin account', () {
      expect(defaultMobileHomeForAccountType('admin'), '/admin');
    });
  });

  group('resolveAppRedirect — admin', () {
    test('sends admin from login to admin panel', () {
      expect(
        resolveAppRedirect(
          isLoading: false,
          isAuthenticated: true,
          path: '/login',
          accountType: 'admin',
        ),
        '/admin',
      );
    });

    test('redirects parent away from admin panel', () {
      expect(
        resolveAppRedirect(
          isLoading: false,
          isAuthenticated: true,
          path: '/admin',
          accountType: 'parent',
        ),
        '/parent',
      );
    });

    test('redirects admin away from parent panel', () {
      expect(
        resolveAppRedirect(
          isLoading: false,
          isAuthenticated: true,
          path: '/parent',
          accountType: 'admin',
        ),
        '/admin',
      );
    });

    test('redirects admin from legacy home placeholder', () {
      expect(
        resolveAppRedirect(
          isLoading: false,
          isAuthenticated: true,
          path: '/home',
          accountType: 'admin',
        ),
        '/admin',
      );
    });

    test('allows admin on admin routes', () {
      expect(
        resolveAppRedirect(
          isLoading: false,
          isAuthenticated: true,
          path: '/admin/account',
          accountType: 'admin',
        ),
        isNull,
      );
    });
  });
}
