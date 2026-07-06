import 'package:larnes_mobile/l10n/app_localizations.dart';

const kioskScanKnownErrorCodes = {
  'camera',
  'error',
  'forbidden',
  'invalid_token',
  'lesson_inactive',
  'network',
  'not_in_group',
  'rate_limited',
  'revoked',
};

String kioskScanErrorMessage(AppLocalizations l10n, String code) {
  switch (code) {
    case 'camera':
      return l10n.kioskScanErrorCamera;
    case 'forbidden':
      return l10n.kioskScanErrorForbidden;
    case 'invalid_token':
      return l10n.kioskScanErrorInvalidToken;
    case 'lesson_inactive':
      return l10n.kioskScanErrorLessonInactive;
    case 'network':
      return l10n.kioskScanErrorNetwork;
    case 'not_in_group':
      return l10n.kioskScanErrorNotInGroup;
    case 'rate_limited':
      return l10n.kioskScanErrorRateLimited;
    case 'revoked':
      return l10n.kioskScanErrorRevoked;
    case 'error':
    default:
      return l10n.kioskScanErrorGeneric;
  }
}

String? kioskScanErrorMessageFromApiCode(AppLocalizations l10n, String? code) {
  if (code == null || code.isEmpty) {
    return null;
  }
  if (kioskScanKnownErrorCodes.contains(code)) {
    return kioskScanErrorMessage(l10n, code);
  }
  return l10n.kioskScanErrorGeneric;
}
