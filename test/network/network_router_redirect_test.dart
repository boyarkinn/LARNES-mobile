import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/core/routing/home_path_mapper.dart';

void main() {
  group('resolveAppRedirect', () {
    test('sends unauthenticated users to login', () {
      expect(
        resolveAppRedirect(
          isLoading: false,
          isAuthenticated: false,
          path: '/network',
          accountType: null,
        ),
        '/login',
      );
    });

    test('allows auth routes while unauthenticated', () {
      expect(
        resolveAppRedirect(
          isLoading: false,
          isAuthenticated: false,
          path: '/login',
          accountType: null,
        ),
        isNull,
      );
    });

    test('does not redirect while session is loading', () {
      expect(
        resolveAppRedirect(
          isLoading: true,
          isAuthenticated: false,
          path: '/network',
          accountType: null,
        ),
        isNull,
      );
    });

    test('redirects parent away from network panel', () {
      expect(
        resolveAppRedirect(
          isLoading: false,
          isAuthenticated: true,
          path: '/network',
          accountType: 'parent',
        ),
        '/home',
      );
    });

    test('redirects network owner away from parent panel', () {
      expect(
        resolveAppRedirect(
          isLoading: false,
          isAuthenticated: true,
          path: '/parent',
          accountType: 'network_owner',
        ),
        '/network',
      );
    });

    test('allows network owner on network route', () {
      expect(
        resolveAppRedirect(
          isLoading: false,
          isAuthenticated: true,
          path: '/network',
          accountType: 'network_owner',
        ),
        isNull,
      );
    });

    test('allows staff on network route', () {
      expect(
        resolveAppRedirect(
          isLoading: false,
          isAuthenticated: true,
          path: '/network',
          accountType: 'staff',
        ),
        isNull,
      );
    });

    test('sends authenticated user from login to account home', () {
      expect(
        resolveAppRedirect(
          isLoading: false,
          isAuthenticated: true,
          path: '/login',
          accountType: 'network_owner',
        ),
        '/network',
      );

      expect(
        resolveAppRedirect(
          isLoading: false,
          isAuthenticated: true,
          path: '/splash',
          accountType: 'parent',
        ),
        '/parent',
      );
    });
  });
}
