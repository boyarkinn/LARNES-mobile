import 'package:app_links/app_links.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Maps https://larnes.ru/{locale}/invite/... → in-app /invite/... path.
String? mapInviteUriToAppPath(Uri uri) {
  final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
  if (segments.isEmpty) {
    return null;
  }

  var inviteIndex = segments.indexOf('invite');
  if (inviteIndex < 0) {
    return null;
  }

  final inviteParts = segments.sublist(inviteIndex);
  if (inviteParts.length < 2) {
    return null;
  }

  var kind = inviteParts[1];
  if (kind == 'preaccount-claim') {
    kind = 'family-adult-claim';
  }

  final allowed = {
    'family-adult-claim',
    'family-guardian',
    'family-join-request',
  };
  if (!allowed.contains(kind)) {
    return null;
  }

  final token = uri.queryParameters['token']?.trim() ?? '';
  if (token.isEmpty) {
    return '/invite/$kind';
  }
  return '/invite/$kind?token=${Uri.encodeComponent(token)}';
}

/// Listens for App Links / Universal Links and navigates via [router].
class InviteDeepLinkBinder extends StatefulWidget {
  const InviteDeepLinkBinder({
    super.key,
    required this.router,
    required this.child,
  });

  final GoRouter router;
  final Widget child;

  @override
  State<InviteDeepLinkBinder> createState() => _InviteDeepLinkBinderState();
}

class _InviteDeepLinkBinderState extends State<InviteDeepLinkBinder> {
  final _appLinks = AppLinks();
  var _bound = false;

  @override
  void initState() {
    super.initState();
    _bind();
  }

  Future<void> _bind() async {
    if (_bound) {
      return;
    }
    _bound = true;

    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) {
        _go(initial);
      }
    } catch (_) {
      // ignore cold-start parse errors
    }

    _appLinks.uriLinkStream.listen((uri) {
      _go(uri);
    }, onError: (_) {});
  }

  void _go(Uri uri) {
    final path = mapInviteUriToAppPath(uri);
    if (path == null || path.isEmpty) {
      return;
    }
    widget.router.go(path);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
