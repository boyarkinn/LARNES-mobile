import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/core/routing/home_path_mapper.dart';

void main() {
  group('mapHomePathToMobile', () {
    test('maps parent and network web paths', () {
      expect(mapHomePathToMobile('/parent'), '/parent');
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
  });
}
