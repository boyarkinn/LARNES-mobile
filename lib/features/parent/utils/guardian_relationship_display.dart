import 'package:larnes_mobile/core/api/guardians_api.dart';

/// Подпись роли опекуна в семье.
String guardianRelationshipLabel(dynamic l10n, String relationship) {
  switch (relationship) {
    case 'father':
      return l10n.parentGuardiansRelationshipFather;
    case 'grandmother':
      return l10n.parentGuardiansRelationshipGrandmother;
    case 'grandfather':
      return l10n.parentGuardiansRelationshipGrandfather;
    case 'mother':
    default:
      return l10n.parentGuardiansRelationshipMother;
  }
}

String? selfGuardianRelationship(GuardiansSnapshot? snapshot) {
  if (snapshot == null) {
    return null;
  }
  for (final guardian in snapshot.guardians) {
    if (guardian.isSelf) {
      return guardian.relationship;
    }
  }
  return null;
}
