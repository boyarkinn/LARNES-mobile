import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/features/kiosk/utils/kiosk_scan_error_message.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';

void main() {
  group('kioskScanErrorMessage', () {
    test('maps known scan error codes', () {
      final l10n = lookupAppLocalizations(const Locale('ru'));

      expect(kioskScanErrorMessage(l10n, 'revoked'), l10n.kioskScanErrorRevoked);
      expect(
        kioskScanErrorMessage(l10n, 'invalid_token'),
        l10n.kioskScanErrorInvalidToken,
      );
      expect(kioskScanErrorMessage(l10n, 'unknown'), l10n.kioskScanErrorGeneric);
    });

    test('maps api code helper', () {
      final l10n = lookupAppLocalizations(const Locale('ru'));

      expect(
        kioskScanErrorMessageFromApiCode(l10n, 'not_in_group'),
        l10n.kioskScanErrorNotInGroup,
      );
      expect(kioskScanErrorMessageFromApiCode(l10n, null), isNull);
    });
  });
}
