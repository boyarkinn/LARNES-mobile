import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';

void main() {
  test('mobile auth OTP skips Turnstile via server preverified flag', () {
    final repoRoot = Directory.current.path.contains('larnes-mobile')
        ? Directory.current.parent
        : Directory.current;
    final source = File(
      '${repoRoot.path}${Platform.pathSeparator}platform${Platform.pathSeparator}'
      'src${Platform.pathSeparator}server${Platform.pathSeparator}auth${Platform.pathSeparator}'
      'perform-registration-otp.ts',
    ).readAsStringSync();

    expect(source, contains('Turnstile не используется'));
    expect(source, contains('preverified: true'));
  });

  test('auth l10n RU/EN hub and wizard keys differ', () {
    final ru = lookupAppLocalizations(const Locale('ru'));
    final en = lookupAppLocalizations(const Locale('en'));

    expect(ru.registerHubParent, isNot(equals(en.registerHubParent)));
    expect(ru.registerWizardStepContact, 'Контакт');
    expect(en.registerWizardStepContact, 'Contact');
    expect(ru.passwordResetWizardStepPassword, 'Новый пароль');
    expect(en.passwordResetWizardStepPassword, 'New password');
    expect(ru.loginFieldLabel, 'Email или телефон');
    expect(en.loginFieldLabel, 'Email or phone');
  });
}
