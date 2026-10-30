import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/core/locale/locale_controller.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/parent/models/lesson_call_pass.dart';
import 'package:larnes_mobile/features/parent/models/lesson_child_board.dart';
import 'package:larnes_mobile/features/parent/widgets/lesson_call_stage.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';

class _WebController extends PlatformInAppWebViewController {
  _WebController()
    : super.implementation(
        const PlatformInAppWebViewControllerCreationParams(id: 'test'),
      );
  final scripts = <String>[];
  String? origin;
  @override
  void addJavaScriptHandler({
    required String handlerName,
    required JavaScriptHandlerCallback callback,
  }) {}
  @override
  Future<dynamic> evaluateJavascript({
    required String source,
    ContentWorld? contentWorld,
  }) async {
    scripts.add(source);
    return null;
  }

  @override
  Future<void> loadData({
    required String data,
    String mimeType = 'text/html',
    String encoding = 'utf8',
    WebUri? baseUrl,
    Uri? androidHistoryUrl,
    WebUri? historyUrl,
    Uri? iosAllowingReadAccessTo,
    WebUri? allowingReadAccessTo,
  }) async {
    origin = baseUrl?.toString();
  }

  @override
  void dispose({bool isKeepAlive = false}) {}
}

class _WebWidget extends PlatformInAppWebViewWidget {
  _WebWidget(super.params, this.controller) : super.implementation();
  final _WebController controller;
  bool created = false;
  @override
  Widget build(BuildContext context) {
    if (!created) {
      created = true;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => params.onWebViewCreated?.call(
          controllerFromPlatform<InAppWebViewController>(controller),
        ),
      );
    }
    return const SizedBox.expand();
  }

  @override
  T controllerFromPlatform<T>(PlatformInAppWebViewController controller) =>
      params.controllerFromPlatform!(controller) as T;
  @override
  void dispose() {}
}

class _WebPlatform extends InAppWebViewPlatform {
  final controller = _WebController();
  _WebWidget? view;
  @override
  PlatformInAppWebViewWidget createPlatformInAppWebViewWidget(
    PlatformInAppWebViewWidgetCreationParams params,
  ) => view = _WebWidget(params, controller);
}

void main() {
  testWidgets(
    'the shared pupil stage loads and polls a board without any call-pass request',
    (tester) async {
      // The native WebView is replaced here; actual HTML/SDK execution is a separate check.
      rootBundle.evict('assets/call/lesson_call_stage.html');
      rootBundle.evict('assets/call/larnes-board.js');
      tester.binding.defaultBinaryMessenger.setMockMessageHandler(
        'flutter/assets',
        (message) async {
          final path = utf8.decode(
            message!.buffer.asUint8List(
              message.offsetInBytes,
              message.lengthInBytes,
            ),
          );
          return ByteData.sublistView(
            utf8.encode(path.endsWith('.html') ? '<html></html>' : 'void 0;'),
          );
        },
      );
      addTearDown(() {
        tester.binding.defaultBinaryMessenger.setMockMessageHandler(
          'flutter/assets',
          null,
        );
        rootBundle.evict('assets/call/lesson_call_stage.html');
        rootBundle.evict('assets/call/larnes-board.js');
      });
      final platform = _WebPlatform();
      InAppWebViewPlatform.instance = platform;
      final locale = LocaleController();
      var passes = 0, snapshots = 0;
      String? boardLink;
      await tester.pumpWidget(
        LocaleScope(
          localeController: locale,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ru'),
            home: Scaffold(
              body: LessonCallStage(
                body: null,
                childId: 'child-1',
                onLeave: () {},
                trainerOpen: false,
                workspaceFormat: 'board',
                mediaEnabled: false,
                captureOnJoin: false,
                fetchPass: (_) async {
                  passes++;
                  return const LessonCallPassOutcome.none();
                },
                fetchBoard: ({String? link}) async {
                  snapshots++;
                  boardLink = link;
                  return LessonChildBoard.fromJson({
                    'status': 'ok',
                    'lessonSessionId': 'lesson-1',
                    'focusRoomId': 'main',
                    'roomEpoch': 0,
                    'sceneRevision': 1,
                    'scene': [],
                    'exercises': [],
                  });
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(platform.controller.origin, startsWith('https://larnes.ru'));
      final web = platform.view!;
      web.params.onLoadStop?.call(
        web.controllerFromPlatform<InAppWebViewController>(platform.controller),
        WebUri('https://larnes.ru/'),
      );
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 550));
      expect(snapshots, greaterThan(0));
      expect(boardLink, isNotEmpty);
      expect(passes, 0);
      expect(
        platform.controller.scripts.any(
          (value) => value.startsWith('openWorkspace('),
        ),
        isTrue,
      );
      expect(
        platform.controller.scripts.any(
          (value) => value.startsWith('setChildRoom('),
        ),
        isTrue,
      );
      expect(
        platform.controller.scripts.any(
          (value) =>
              value.startsWith('join(') || value.startsWith('acceptPass('),
        ),
        isFalse,
      );
      await tester.pumpWidget(const SizedBox());
      locale.dispose();
    },
  );
}
