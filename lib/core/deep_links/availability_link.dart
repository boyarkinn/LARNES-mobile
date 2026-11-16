/// Keep public poll credentials in the fragment, just as in the browser.
bool isLarnesWebLink(Uri uri) =>
    uri.scheme == 'https' &&
    uri.host == 'larnes.ru' &&
    uri.port == 443 &&
    uri.userInfo.isEmpty;

String? mapAvailabilityUriToAppPath(Uri uri) {
  if (!isLarnesWebLink(uri)) return null;
  final match = RegExp(
    r'^/(?:(ru|en|ar)/)?availability/?$',
  ).firstMatch(uri.path);
  if (match == null) return null;
  return Uri(
    path: '/availability',
    queryParameters: {if (match.group(1) != null) 'locale': match.group(1)!},
    fragment: uri.fragment,
  ).toString();
}

Uri availabilityWebUri(
  Uri route, {
  required String baseUrl,
  required String locale,
}) {
  final requested = route.queryParameters['locale'] ?? locale;
  final language = const ['ru', 'en', 'ar'].contains(requested)
      ? requested
      : 'en';
  Map<String, String> fragment;
  try {
    fragment = Uri.splitQueryString(route.fragment);
  } on FormatException {
    fragment = {};
  }
  final kind = fragment.containsKey('poll') ? 'poll' : 'token';
  final credential = fragment[kind] ?? '';
  return Uri.parse(baseUrl).replace(
    path: '/$language/availability',
    queryParameters: {'app': '1'},
    fragment: Uri(queryParameters: {kind: credential}).query,
  );
}

bool isAvailabilityWebUri(Uri uri, Uri origin) =>
    uri.scheme == origin.scheme &&
    uri.host == origin.host &&
    uri.port == origin.port &&
    uri.userInfo.isEmpty &&
    RegExp(r'^/(ru|en|ar)/availability/?$').hasMatch(uri.path);
