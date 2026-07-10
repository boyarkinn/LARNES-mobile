import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/core/api/admin_account_api.dart';

void main() {
  group('AdminAccountSnapshot.fromJson', () {
    test('parses admin hub payload', () {
      final snapshot = AdminAccountSnapshot.fromJson({
        'status': 'success',
        'user': {
          'id': 'admin-1',
          'accountType': 'admin',
          'firstName': 'Alex',
          'lastName': 'Admin',
          'patronymic': 'A.',
          'phone': '+79990001122',
          'phoneVerifiedAt': '2026-07-10T12:00:00.000Z',
          'email': 'admin@example.com',
          'emailVerifiedAt': null,
          'login': 'alexadmin',
        },
      });

      expect(snapshot.user.id, 'admin-1');
      expect(snapshot.user.accountType, 'admin');
      expect(snapshot.user.firstName, 'Alex');
      expect(snapshot.user.lastName, 'Admin');
      expect(snapshot.user.login, 'alexadmin');
      expect(snapshot.user.phoneVerified, isTrue);
      expect(snapshot.user.emailVerified, isFalse);
      expect(snapshot.user.fullName, 'Admin Alex A.');
    });
  });
}
