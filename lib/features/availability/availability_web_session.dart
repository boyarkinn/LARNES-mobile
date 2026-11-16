import 'dart:async';
import 'dart:convert';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// A native-only, HttpOnly session limited to the existing availability API.
/// Serialize old-screen cleanup and new-screen preparation on rapid link changes.
class AvailabilityWebSession {
  AvailabilityWebSession({required this.origin, CookieManager? cookies})
    : cookies = cookies ?? CookieManager.instance();

  static const path = '/api/schedule/availability';
  static const accountCookie = 'larnes-availability-account';
  static Future<void> _queue = Future.value();
  static Object? _owner;
  final Uri origin;
  final CookieManager cookies;
  final _lease = Object();
  bool _closed = false;

  Future<void> _serial(Future<void> Function() action) {
    final next = _queue.then((_) => action());
    _queue = next.catchError((Object _) {});
    return next;
  }

  Future<void> prepare({required String? userId, required String? token}) =>
      _serial(() async {
        if (_closed) return;
        _owner = _lease;
        if (userId == null && token != null) {
          throw StateError('availability-account-not-restored');
        }
        if (userId != null) {
          final parts = token?.split('.');
          if (parts == null ||
              parts.length != 3 ||
              (jsonDecode(
                        utf8.decode(
                          base64Url.decode(base64Url.normalize(parts[1])),
                        ),
                      )
                      as Map)['userId'] !=
                  userId) {
            throw StateError('availability-account-mismatch');
          }
        }
        await _deleteCookies();
        if (userId == null) return;
        final url = WebUri(origin.toString());
        for (final entry in {'session': token!, accountCookie: '1'}.entries) {
          final saved = await cookies.setCookie(
            url: url,
            name: entry.key,
            value: entry.value,
            path: path,
            isSecure: origin.scheme == 'https',
            isHttpOnly: true,
            sameSite: HTTPCookieSameSitePolicy.LAX,
          );
          if (!saved) throw StateError('availability-cookie');
        }
      });

  Future<void> _deleteCookies() async {
    for (final name in ['session', accountCookie]) {
      await cookies.deleteCookie(
        url: WebUri(origin.toString()),
        name: name,
        path: path,
      );
    }
  }

  Future<void> clear() {
    _closed = true;
    return _serial(() async {
      if (!identical(_owner, _lease)) return;
      _owner = null;
      await _deleteCookies();
    });
  }
}
