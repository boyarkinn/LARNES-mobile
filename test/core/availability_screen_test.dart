import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/core/api/auth_api.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';
import 'package:larnes_mobile/core/auth/auth_session.dart';
import 'package:larnes_mobile/features/availability/availability_screen.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';

class _Auth extends ChangeNotifier implements AuthSession {
  final ready = Completer<void>();
  int bootstraps = 0;
  @override
  bool isLoading = true;
  @override
  AuthUser? get user => null;
  @override
  Future<void> bootstrap() async {
    bootstraps++;
    await ready.future;
    isLoading = false;
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Cookies extends PlatformCookieManager {
  _Cookies()
    : super.implementation(const PlatformCookieManagerCreationParams());
  int clears = 0;
  @override
  Future<bool> deleteCookie({
    required WebUri url,
    required String name,
    String path = '/',
    String? domain,
    PlatformInAppWebViewController? iosBelow11WebViewController,
    PlatformInAppWebViewController? webViewController,
  }) async {
    clears++;
    return true;
  }
}

class _Controller extends PlatformInAppWebViewController {
  _Controller(this.url)
    : super.implementation(
        const PlatformInAppWebViewControllerCreationParams(id: 'availability'),
      );
  final WebUri? url;
  final handlers = <String, JavaScriptHandlerCallback>{};
  int backs = 0;
  @override
  Future<WebUri?> getUrl() async => url;
  @override
  void addJavaScriptHandler({
    required String handlerName,
    required JavaScriptHandlerCallback callback,
  }) {
    handlers[handlerName] = callback;
  }

  @override
  Future<dynamic> evaluateJavascript({
    required String source,
    ContentWorld? contentWorld,
  }) async {
    backs++;
    return true;
  }

  @override
  void dispose({bool isKeepAlive = false}) {}
}

class _Web extends PlatformInAppWebViewWidget {
  _Web(super.params) : super.implementation() {
    controller = _Controller(params.initialUrlRequest?.url);
  }
  late final _Controller controller;
  bool created = false;
  @override
  Widget build(BuildContext context) {
    if (!created) {
      created = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final web = controllerFromPlatform<InAppWebViewController>(controller);
        params.onWebViewCreated?.call(web);
        params.onLoadStop?.call(web, controller.url);
      });
    }
    return const SizedBox.expand();
  }

  @override
  T controllerFromPlatform<T>(PlatformInAppWebViewController controller) =>
      params.controllerFromPlatform!(controller) as T;
  @override
  void dispose() {}
}

class _Platform extends InAppWebViewPlatform {
  final cookies = _Cookies();
  final views = <_Web>[];
  @override
  PlatformCookieManager createPlatformCookieManager(
    PlatformCookieManagerCreationParams params,
  ) => cookies;
  @override
  PlatformInAppWebViewWidget createPlatformInAppWebViewWidget(
    PlatformInAppWebViewWidgetCreationParams params,
  ) {
    final web = _Web(params);
    views.add(web);
    return web;
  }
}

void main() {
  testWidgets(
    'cold link waits for account restore; native Back, keyboard rebuild and network retry keep one active WebView',
    (tester) async {
      FlutterSecureStorage.setMockInitialValues({});
      final previous = InAppWebViewPlatform.instance;
      final platform = _Platform();
      InAppWebViewPlatform.instance = platform;
      final auth = _Auth();
      addTearDown(() {
        if (previous != null) InAppWebViewPlatform.instance = previous;
        auth.dispose();
      });
      await tester.pumpWidget(
        AuthScope(
          authSession: auth,
          child: MaterialApp(
            locale: const Locale('ru'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: AvailabilityScreen(
              route: Uri.parse(
                '/availability?locale=ru#poll=abcdefghijklmnopABCDEFGHIJKLMNOP',
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(auth.bootstraps, 1);
      expect(
        platform.views,
        isEmpty,
        reason: 'never load guest content while the account is still restoring',
      );
      auth.ready.complete();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 20));
      }
      expect(platform.views.length, 1);
      final web = platform.views.single;
      expect(
        web.controller.url!.fragment,
        'poll=abcdefghijklmnopABCDEFGHIJKLMNOP',
      );
      expect(web.controller.url!.query, 'app=1');
      await web.controller.handlers['availabilityNavigation']!([
        {'canGoBack': true, 'busy': false},
      ]);
      await tester.pump();
      expect(
        find.byType(AppBar),
        findsNothing,
        reason: 'the calendar has no second native toolbar',
      );
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(web.controller.backs, 1);
      await web.controller.handlers['availabilityNavigation']!([
        {'canGoBack': true, 'busy': true},
      ]);
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(
        web.controller.backs,
        1,
        reason: 'Back cannot interrupt a pending response or drag',
      );
      tester.view.viewInsets = const FakeViewPadding(bottom: 260);
      await tester.pump();
      expect(
        platform.views.length,
        1,
        reason: 'opening the keyboard does not reload the form',
      );
      tester.view.resetViewInsets();
      final controller = web.controllerFromPlatform<InAppWebViewController>(
        web.controller,
      );
      web.params.onReceivedError?.call(
        controller,
        WebResourceRequest(
          url: WebUri('https://larnes.ru/api/schedule/availability/shared'),
          isForMainFrame: false,
        ),
        WebResourceError(
          type: WebResourceErrorType.NOT_CONNECTED_TO_INTERNET,
          description: 'offline',
        ),
      );
      await tester.pump();
      expect(
        find.text('Попробовать ещё раз'),
        findsNothing,
        reason: 'API failures stay inside the web form and retain the draft',
      );
      web.params.onReceivedError?.call(
        controller,
        WebResourceRequest(url: web.controller.url!, isForMainFrame: true),
        WebResourceError(
          type: WebResourceErrorType.NOT_CONNECTED_TO_INTERNET,
          description: 'offline',
        ),
      );
      await tester.pump();
      expect(find.text('Попробовать ещё раз'), findsOneWidget);
      await tester.tap(find.text('Попробовать ещё раз'));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 20));
      }
      expect(platform.views.length, 2);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      expect(platform.cookies.clears, greaterThanOrEqualTo(6));
      expect(tester.takeException(), isNull);
    },
  );
}
