import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/core/deep_links/availability_link.dart';
import 'package:larnes_mobile/core/routing/home_path_mapper.dart';

void main() {
  const token = 'abcdefghijklmnopABCDEFGHIJKLMNOP';
  test(
    'shared and personal poll links retain their fragments for every supported locale',
    () {
      for (final prefix in ['', '/ru', '/en', '/ar']) {
        for (final kind in ['poll', 'token']) {
          final path = mapAvailabilityUriToAppPath(
            Uri.parse('https://larnes.ru$prefix/availability#$kind=$token'),
          )!;
          final web = availabilityWebUri(
            Uri.parse(path),
            baseUrl: 'https://larnes.ru',
            locale: 'ru',
          );
          expect(web.fragment, '$kind=$token');
          expect(web.queryParameters, {'app': '1'});
          expect(web.path, '${prefix.isEmpty ? '/ru' : prefix}/availability');
          expect(web.query.contains(token), isFalse);
        }
      }
    },
  );
  test(
    'unrelated origins and lookalike paths cannot become app poll links',
    () {
      for (final url in [
        'https://foreign.test/ru/availability#poll=$token',
        'http://larnes.ru/ru/availability',
        'https://larnes.ru.evil.test/ru/availability',
        'https://other@larnes.ru/ru/availability',
        'https://larnes.ru:444/availability',
        'https://larnes.ru/ru/availability/other',
        'https://larnes.ru/ru/availability-evil',
      ]) {
        expect(mapAvailabilityUriToAppPath(Uri.parse(url)), isNull);
      }
      expect(
        isAvailabilityWebUri(
          Uri.parse('https://larnes.ru/ru/login'),
          Uri.parse('https://larnes.ru'),
        ),
        isFalse,
      );
    },
  );
  test(
    'guest, cold-start and incomplete-family accounts can open a public poll',
    () {
      for (final loading in [true, false]) {
        for (final signedIn in [true, false]) {
          expect(
            resolveAppRedirect(
              isLoading: loading,
              isAuthenticated: signedIn,
              path: '/availability',
              accountType: signedIn ? 'parent' : null,
              familySetupComplete: false,
            ),
            isNull,
          );
        }
      }
      expect(
        resolveAppRedirect(
          isLoading: false,
          isAuthenticated: false,
          path: '/parent',
          accountType: null,
        ),
        '/login',
      );
    },
  );
}
