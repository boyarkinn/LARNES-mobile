import 'dart:convert';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/features/availability/availability_web_session.dart';

class _Cookies extends CookieManager {
  _Cookies() : super.fromPlatform(_CookiePlatform());
  final values = <String, String>{};
  final secured = <String>[];
  @override
  Future<bool> setCookie({
    required WebUri url,
    required String name,
    required String value,
    String path = '/',
    String? domain,
    int? expiresDate,
    int? maxAge,
    bool? isSecure,
    bool? isHttpOnly,
    HTTPCookieSameSitePolicy? sameSite,
    InAppWebViewController? iosBelow11WebViewController,
    InAppWebViewController? webViewController,
  }) async {
    expect(url.host, 'larnes.ru');
    expect(path, AvailabilityWebSession.path);
    expect(isSecure, isTrue);
    expect(isHttpOnly, isTrue);
    expect(sameSite, HTTPCookieSameSitePolicy.LAX);
    expect(domain, isNull);
    secured.add(name);
    values[name] = value;
    return true;
  }

  @override
  Future<bool> deleteCookie({
    required WebUri url,
    required String name,
    String path = '/',
    String? domain,
    InAppWebViewController? iosBelow11WebViewController,
    InAppWebViewController? webViewController,
  }) async {
    expect(path, AvailabilityWebSession.path);
    values.remove(name);
    return true;
  }
}

class _CookiePlatform extends PlatformCookieManager {
  _CookiePlatform()
    : super.implementation(const PlatformCookieManagerCreationParams());
}

String _token(String user) =>
    'header.${base64Url.encode(utf8.encode(jsonEncode({'userId': user})))}.signature';

void main() {
  test(
    'account cookie is scoped and HttpOnly; cleanup does not remove the guest proof',
    () async {
      final cookies = _Cookies()
        ..values['larnes-availability-browser'] = 'guest-proof';
      final session = AvailabilityWebSession(
        origin: Uri.parse('https://larnes.ru'),
        cookies: cookies,
      );
      await session.prepare(userId: 'parent', token: _token('parent'));
      expect(cookies.values['session'], _token('parent'));
      expect(cookies.values[AvailabilityWebSession.accountCookie], '1');
      await session.clear();
      expect(cookies.values, {'larnes-availability-browser': 'guest-proof'});
    },
  );
  test(
    'late old-screen cleanup never clears the newer account, including rapid link replacement',
    () async {
      final cookies = _Cookies();
      final first = AvailabilityWebSession(
        origin: Uri.parse('https://larnes.ru'),
        cookies: cookies,
      );
      final second = AvailabilityWebSession(
        origin: Uri.parse('https://larnes.ru'),
        cookies: cookies,
      );
      await first.prepare(userId: 'first', token: _token('first'));
      await second.prepare(userId: 'second', token: _token('second'));
      await first.clear();
      expect(cookies.values['session'], _token('second'));
      await second.clear();
      expect(cookies.values, isEmpty);
    },
  );
  test(
    'guest startup clears previous account cookies and never copies an unrestored or different account',
    () async {
      final cookies = _Cookies()..values['session'] = 'old-account';
      var session = AvailabilityWebSession(
        origin: Uri.parse('https://larnes.ru'),
        cookies: cookies,
      );
      await session.prepare(userId: null, token: null);
      expect(cookies.values, isEmpty);
      await session.clear();
      for (final user in [null, 'different']) {
        session = AvailabilityWebSession(
          origin: Uri.parse('https://larnes.ru'),
          cookies: cookies,
        );
        await expectLater(
          session.prepare(userId: user, token: _token('parent')),
          throwsStateError,
        );
        await session.clear();
      }
      expect(cookies.secured, isEmpty);
    },
  );
}
