import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/auth/auth_session.dart';
import 'package:larnes_mobile/core/auth/token_storage.dart';
import 'package:larnes_mobile/core/config/app_config.dart';
import 'package:larnes_mobile/core/deep_links/availability_link.dart';
import 'package:larnes_mobile/core/routing/home_path_mapper.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';
import 'availability_web_session.dart';

class AvailabilityScreen extends StatefulWidget {
  const AvailabilityScreen({super.key, required this.route});
  final Uri route;
  @override
  State<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends State<AvailabilityScreen> {
  AuthSession? _auth;
  AvailabilityWebSession? _session;
  InAppWebViewController? _web;
  Widget? _view;
  Uri? _url;
  String? _accountId;
  bool _preparing = false, _failed = false, _loading = true;
  bool _internalBack = false, _busy = false, _leaving = false;
  int _revision = 0;

  // The plugin can wrap the same platform controller in different Dart objects.
  bool _current(InAppWebViewController web) =>
      mounted && identical(web.platform, _web?.platform);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = AuthScope.of(context);
    if (identical(_auth, auth)) return;
    _auth?.removeListener(_authChanged);
    _auth = auth;
    auth.addListener(_authChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_prepare());
    });
  }

  void _authChanged() {
    if (!_preparing && mounted && _auth?.user?.id != _accountId) {
      unawaited(_prepare());
    }
  }

  Future<void> _prepare() async {
    if (_preparing || !mounted) return;
    final revision = ++_revision;
    _preparing = true;
    setState(() {
      _url = null;
      _web = null;
      _view = null;
      _loading = true;
      _failed = false;
      _internalBack = false;
      _busy = false;
    });
    try {
      await _session?.clear();
      if (_auth!.isLoading) await _auth!.bootstrap();
      if (!mounted || revision != _revision) return;
      final accountId = _auth!.user?.id;
      final token = await TokenStorage().readToken();
      if (!mounted || revision != _revision) return;
      final origin = Uri.parse(AppConfig.apiBaseUrl);
      final session = AvailabilityWebSession(origin: origin);
      _session = session;
      await session.prepare(userId: accountId, token: token);
      if (!mounted || revision != _revision) return;
      if (_auth!.user?.id != accountId) {
        await session.clear();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) unawaited(_prepare());
        });
        return;
      }
      _accountId = accountId;
      final url = availabilityWebUri(
        widget.route,
        baseUrl: AppConfig.apiBaseUrl,
        locale: Localizations.localeOf(context).languageCode,
      );
      setState(() {
        _url = url;
      });
    } catch (_) {
      await _session?.clear().catchError((Object _) {});
      if (mounted && revision == _revision) {
        setState(() {
          _failed = true;
          _loading = false;
        });
      }
    } finally {
      _preparing = false;
    }
  }

  @override
  void dispose() {
    _revision++;
    _auth?.removeListener(_authChanged);
    unawaited(_session?.clear().catchError((Object _) {}));
    super.dispose();
  }

  Future<void> _back() async {
    if (_busy || _leaving) return;
    final web = _web;
    if (web != null && !_failed) {
      try {
        final handled = await web.evaluateJavascript(
          source: 'window.larnesAvailabilityBack?.() ?? false',
        );
        if (handled == true) return;
      } catch (_) {
        /* A failed/closed main frame can still be exited. */
      }
    }
    if (!mounted) return;
    setState(() {
      _leaving = true;
    });
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(
      _auth!.isAuthenticated
          ? resolveAuthenticatedHome(
              accountType: _auth!.user?.accountType,
              familySetupComplete: _auth!.familySetupComplete,
            )
          : '/login',
    );
  }

  Future<NavigationActionPolicy> _navigation(
    InAppWebViewController web,
    NavigationAction action,
  ) async {
    final uri = action.request.url;
    if (uri == null) return NavigationActionPolicy.CANCEL;
    if (isAvailabilityWebUri(uri, Uri.parse(AppConfig.apiBaseUrl))) {
      return NavigationActionPolicy.ALLOW;
    }
    if (action.isForMainFrame == true && uri.scheme == 'https') {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return NavigationActionPolicy.CANCEL;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PopScope(
      canPop: _leaving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_back());
      },
      child: Scaffold(
        appBar: !_internalBack || _failed
            ? AppBar(
                toolbarHeight: 44,
                title: Text(l10n.availabilityTitle),
                leading: IconButton(
                  onPressed: _busy ? null : _back,
                  tooltip: l10n.parentBack,
                  icon: const Icon(Icons.arrow_back),
                ),
              )
            : null,
        body: SafeArea(
          child: _failed
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.availabilityLoadFailed,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _prepare,
                          child: Text(l10n.availabilityRetry),
                        ),
                      ],
                    ),
                  ),
                )
              : Stack(
                  children: [
                    if (_url != null)
                      // Keep the platform view stable across keyboard and toolbar rebuilds.
                      (_view ??= InAppWebView(
                        key: ValueKey(_revision),
                        initialUrlRequest: URLRequest(
                          url: WebUri(_url.toString()),
                        ),
                        initialSettings: InAppWebViewSettings(
                          javaScriptEnabled: true,
                          supportZoom: false,
                          useShouldOverrideUrlLoading: true,
                          sharedCookiesEnabled: true,
                          thirdPartyCookiesEnabled: false,
                          disableDefaultErrorPage: true,
                          allowFileAccess: false,
                          allowContentAccess: false,
                        ),
                        onWebViewCreated: (web) {
                          _web = web;
                          web.addJavaScriptHandler(
                            handlerName: 'availabilityNavigation',
                            callback: (arguments) async {
                              final current = await web.getUrl();
                              if (!_current(web) ||
                                  current == null ||
                                  !isAvailabilityWebUri(
                                    current,
                                    Uri.parse(AppConfig.apiBaseUrl),
                                  ) ||
                                  arguments.length != 1 ||
                                  arguments.first is! Map) {
                                return;
                              }
                              final state = arguments.first as Map;
                              setState(() {
                                _internalBack = state['canGoBack'] == true;
                                _busy = state['busy'] == true;
                              });
                            },
                          );
                        },
                        shouldOverrideUrlLoading: _navigation,
                        onLoadStop: (web, _) {
                          if (_current(web)) {
                            setState(() {
                              _loading = false;
                            });
                          }
                        },
                        onReceivedError: (web, request, _) {
                          if (_current(web) && request.isForMainFrame == true) {
                            setState(() {
                              _failed = true;
                              _loading = false;
                            });
                          }
                        },
                        onReceivedHttpError: (web, request, _) {
                          if (_current(web) && request.isForMainFrame == true) {
                            setState(() {
                              _failed = true;
                              _loading = false;
                            });
                          }
                        },
                      )),
                    if (_loading)
                      const Positioned.fill(
                        child: ColoredBox(
                          color: Colors.white,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}
