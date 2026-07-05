import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/features/parent/navigation/parent_navigation.dart';

void main() {
  group('ParentNavigation.showsBottomNav', () {
    test('shows on picker and child drill-down', () {
      expect(ParentNavigation.showsBottomNav('/parent'), isTrue);
      expect(ParentNavigation.showsBottomNav('/parent/child-1'), isTrue);
      expect(ParentNavigation.showsBottomNav('/parent/child-1/homework'), isTrue);
      expect(ParentNavigation.showsBottomNav('/parent/child-1/profile'), isTrue);
      expect(ParentNavigation.showsBottomNav('/parent/account'), isTrue);
      expect(ParentNavigation.showsBottomNav('/parent/account/profile'), isTrue);
    });

    test('hides on homework and program players', () {
      expect(ParentNavigation.showsBottomNav('/parent/child-1/homework/a1'), isFalse);
      expect(ParentNavigation.showsBottomNav('/parent/child-1/programs/p1'), isFalse);
    });
  });
}
