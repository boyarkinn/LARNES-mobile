import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/features/parent/screens/child_profile_screen.dart';

void main() {
  group('childProfileOriginFromQuery', () {
    test('maps account query param', () {
      expect(childProfileOriginFromQuery('account'), ChildProfileOrigin.account);
      expect(childProfileOriginFromQuery('hub'), ChildProfileOrigin.hub);
      expect(childProfileOriginFromQuery(null), ChildProfileOrigin.hub);
    });
  });
}
