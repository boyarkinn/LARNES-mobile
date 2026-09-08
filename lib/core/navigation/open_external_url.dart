import 'package:url_launcher/url_launcher.dart';

/// Opens an https URL in the system browser (not the share sheet).
Future<bool> openExternalUrl(Uri uri) async {
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}

Future<bool> openExternalUrlString(String url) {
  return openExternalUrl(Uri.parse(url));
}
