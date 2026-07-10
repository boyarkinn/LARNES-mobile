import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/core/api/api_error_body.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('ru'));

  group('parseApiJsonBody', () {
    test('parses JSON string from Dio error body', () {
      const raw =
          '{"message":"Пользователь с таким email уже существует.","status":"error"}';
      final map = parseApiJsonBody(raw);
      expect(map?['message'], 'Пользователь с таким email уже существует.');
      expect(map?['status'], 'error');
    });

    test('parses Map body', () {
      final map = parseApiJsonBody({
        'message': 'Пользователь с таким номером телефона уже существует.',
      });
      expect(
        map?['message'],
        'Пользователь с таким номером телефона уже существует.',
      );
    });

    test('parses UTF-8 bytes from Dio error body', () {
      const raw =
          '{"message":"Пользователь с таким email уже существует.","status":"error"}';
      final map = parseApiJsonBody(raw.codeUnits);
      expect(map?['message'], 'Пользователь с таким email уже существует.');
    });
  });

  group('apiMessageFromBody', () {
    test('returns server message for existing email', () {
      expect(
        apiMessageFromBody(
          '{"message":"Пользователь с таким email уже существует.","status":"error"}',
          l10n,
        ),
        'Пользователь с таким email уже существует.',
      );
    });

    test('falls back when body is empty', () {
      expect(
        apiMessageFromBody(null, l10n, fallback: l10n.requestFailed),
        l10n.requestFailed,
      );
    });
  });
}
