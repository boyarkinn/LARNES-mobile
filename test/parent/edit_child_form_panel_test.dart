import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/features/parent/widgets/account/edit_child_form_panel.dart';

void main() {
  group('ageYearsFromIsoDate', () {
    test('computes age from ISO date', () {
      final now = DateTime.now();
      final dob = DateTime(now.year - 7, now.month, now.day);
      final iso =
          '${dob.year}-${dob.month.toString().padLeft(2, '0')}-${dob.day.toString().padLeft(2, '0')}';
      expect(ageYearsFromIsoDate(iso), 7);
    });

    test('returns null for empty input', () {
      expect(ageYearsFromIsoDate(null), isNull);
      expect(ageYearsFromIsoDate(''), isNull);
    });
  });
}
