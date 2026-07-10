import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/features/admin/navigation/admin_navigation.dart';

void main() {
  group('AdminNavigation.showsBottomNav', () {
    test('shows on admin root and account routes', () {
      expect(AdminNavigation.showsBottomNav('/admin'), isTrue);
      expect(AdminNavigation.showsBottomNav('/admin/account'), isTrue);
    });

    test('hides on trainer detail routes', () {
      expect(AdminNavigation.showsBottomNav('/admin/trainers/flashcard-digit-match'), isFalse);
    });

    test('hides outside admin zone', () {
      expect(AdminNavigation.showsBottomNav('/parent'), isFalse);
    });
  });
}
