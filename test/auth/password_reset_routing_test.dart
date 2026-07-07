import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/core/routing/home_path_mapper.dart';

void main() {
  group('isAuthRoute', () {
    test('includes password reset routes for guest access', () {
      expect(isAuthRoute('/login'), isTrue);
      expect(isAuthRoute('/register'), isTrue);
      expect(isAuthRoute('/password-reset'), isTrue);
      expect(isAuthRoute('/password-reset/otp'), isTrue);
      expect(isAuthRoute('/password-reset/password'), isTrue);
      expect(isAuthRoute('/parent'), isFalse);
    });
  });
}
