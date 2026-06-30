import 'package:larnes_mobile/features/parent/models/parent_child.dart';

/// Возраст ребёнка — русская плюрализация без ICU в ARB.
String formatChildAgeYears(int age, String localeCode) {
  if (localeCode == 'en') {
    return age == 1 ? '$age year' : '$age years';
  }

  final mod10 = age % 10;
  final mod100 = age % 100;
  if (mod100 >= 11 && mod100 <= 14) {
    return '$age лет';
  }
  if (mod10 == 1) {
    return '$age год';
  }
  if (mod10 >= 2 && mod10 <= 4) {
    return '$age года';
  }
  return '$age лет';
}

({String givenName, String lastName}) childDisplayNameLines(ParentChild child) {
  final givenParts = [child.firstName, child.patronymic]
      .whereType<String>()
      .where((part) => part.isNotEmpty);
  return (
    givenName: givenParts.join(' '),
    lastName: child.lastName ?? '',
  );
}
