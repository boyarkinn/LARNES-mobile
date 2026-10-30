import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/core/locale/locale_controller.dart';
import 'package:larnes_mobile/core/locale/locale_scope.dart';
import 'package:larnes_mobile/features/parent/models/lesson_call_pass.dart';
import 'package:larnes_mobile/features/parent/models/lesson_child_board.dart';
import 'package:larnes_mobile/features/parent/models/lesson_device_media.dart';
import 'package:larnes_mobile/core/api/kiosk_api.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:larnes_mobile/features/parent/widgets/lesson_call_stage.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';

class _WebController extends PlatformInAppWebViewController {
  _WebController()
    : super.implementation(
        const PlatformInAppWebViewControllerCreationParams(id: 'test'),
      );
  final scripts = <String>[];
  final handlers = <String, JavaScriptHandlerCallback>{};
  int loads = 0;
  String? origin;
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
    loads++;
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

class _MediaHarness {
  final platform = _WebPlatform();
  final locale = LocaleController();
  final wire = <String, dynamic>{
    'assignment': 'assignment-1',
    'childId': 'child-1',
    'deviceId': 'desk-1',
    'lessonSessionId': 'lesson-1',
    'revision': 0,
    'audio': false,
    'video': false,
    'receive': false,
    'phase': 'idle',
  };
  int passes = 0, boards = 0;
  Future<LessonCallPassOutcome> Function()? pass;
  bool home = false;
  Future<void> pump(WidgetTester tester) async {
    rootBundle.evict('assets/call/lesson_call_stage.html');
    rootBundle.evict('assets/call/larnes-board.js');
    tester.binding.defaultBinaryMessenger.setMockMessageHandler(
      'flutter/assets',
      (_) async => ByteData.sublistView(utf8.encode('void 0;')),
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMessageHandler(
        'flutter/assets',
        null,
      );
      rootBundle.evict('assets/call/lesson_call_stage.html');
      rootBundle.evict('assets/call/larnes-board.js');
      locale.dispose();
    });
    InAppWebViewPlatform.instance = platform;
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
              lessonSessionId: 'lesson-1',
              onLeave: () {},
              trainerOpen: false,
              workspaceFormat: 'board',
              mediaEnabled: home,
              captureOnJoin: false,
              fetchMedia: home
                  ? null
                  : () async => LessonDeviceMedia.fromJson(wire),
              sendMedia: home
                  ? null
                  : (body) async {
                      if (body['device'] is String) {
                        wire[body['device'] as String] = body['enabled'];
                        wire['revision'] = (wire['revision'] as int) + 1;
                      }
                      if (body['failedDevice'] == 'call') {
                        wire['audio'] = false;
                        wire['video'] = false;
                        wire['revision'] = (wire['revision'] as int) + 1;
                      }
                      if (body['failedDevice'] == 'video' ||
                          body['failedDevice'] == 'audio') {
                        wire[body['failedDevice'] as String] = false;
                        wire['revision'] = (wire['revision'] as int) + 1;
                      }
                      wire['receive'] =
                          wire['audio'] == true || wire['video'] == true;
                      return LessonDeviceMedia.fromJson(wire);
                    },
              fetchPass: (_, {String? assignment}) async {
                passes++;
                if (pass != null) return pass!();
                return const LessonCallPassOutcome.pass(
                  LessonCallPass(
                    displayName: 'Test',
                    domain: 'meet.example.com',
                    jwt: 'synthetic',
                    room: 'lesson',
                    xmppDomain: 'meet.example.com',
                    workspaceFormat: 'board',
                  ),
                );
              },
              fetchBoard: ({String? link}) async {
                boards++;
                return LessonChildBoard.fromJson({
                  'status': 'ok',
                  'lessonSessionId': 'lesson-1',
                  'focusRoomId': 'main',
                  'roomEpoch': 0,
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
    final web = platform.view!;
    web.params.onLoadStop?.call(
      web.controllerFromPlatform<InAppWebViewController>(platform.controller),
      WebUri('https://larnes.ru/'),
    );
    await tester.pumpAndSettle();
  }

  Future<void> teacher(WidgetTester tester, String device, bool on) async {
    wire[device] = on;
    wire['receive'] = wire['audio'] == true || wire['video'] == true;
    wire['revision'] = (wire['revision'] as int) + 1;
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
  }

  Future<void> emit(
    WidgetTester tester,
    String kind, [
    String detail = '',
  ]) async {
    platform.controller.handlers['lessonCall']!([
      {'kind': kind, 'detail': detail},
    ]);
    await tester.pumpAndSettle();
  }
}

void main() {
  testWidgets(
    'a late failed call-pass cannot cancel a newer microphone request',
    (tester) async {
      final reply = Completer<LessonCallPassOutcome>();
      final f = _MediaHarness()..pass = () => reply.future;
      await f.pump(tester);
      await f.teacher(tester, 'video', true);
      await f.teacher(tester, 'video', false);
      f.pass = null;
      await f.teacher(tester, 'audio', true);
      reply.completeError(
        const KioskApiException('old request', code: 'inactive'),
      );
      await tester.pumpAndSettle();
      expect(f.wire['audio'], isTrue);
      expect(f.passes, 2);
      expect(
        f.platform.controller.scripts.any((s) => s.startsWith('join(')),
        isTrue,
      );
      expect(f.platform.controller.loads, 1);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'cancelling camera permission keeps the active microphone connected',
    (tester) async {
      final camera = Completer<Map<int, int>>();
      const channel = MethodChannel('flutter.baseflow.com/permissions/methods');
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        if (call.method == 'requestPermissions') {
          final values = List<int>.from(call.arguments as List);
          if (values.contains(Permission.camera.value)) return camera.future;
          return {for (final value in values) value: 1};
        }
        return 1;
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );
      final f = _MediaHarness();
      await f.pump(tester);
      await f.teacher(tester, 'audio', true);
      await f.emit(tester, 'joined');
      await f.emit(tester, 'mic-on');
      final pauses = f.platform.controller.scripts
          .where((s) => s == 'pauseMedia()')
          .length;
      await f.teacher(tester, 'video', true);
      await f.teacher(tester, 'video', false);
      camera.complete({Permission.camera.value: 1});
      await tester.pumpAndSettle();
      expect(
        f.platform.controller.scripts,
        isNot(contains('setDevice("video", false)')),
      );
      expect(
        f.platform.controller.scripts,
        contains('setDevice("video", true)'),
      );
      expect(
        f.platform.controller.scripts.where((s) => s == 'pauseMedia()').length,
        pauses,
      );
      expect(f.wire['audio'], isTrue);
      expect(f.platform.controller.loads, 1);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'child can cancel a camera permission prompt and its late grant cannot capture',
    (tester) async {
      final permission = Completer<Map<int, int>>();
      const channel = MethodChannel('flutter.baseflow.com/permissions/methods');
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        if (call.method == 'requestPermissions') return permission.future;
        return 1;
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );
      final f = _MediaHarness();
      await f.pump(tester);
      await tester.tap(find.byIcon(Icons.videocam_off));
      await tester.pumpAndSettle();
      expect(f.wire['video'], isTrue);
      expect(f.passes, 1);
      await f.emit(tester, 'joined');
      await tester.tap(find.byIcon(Icons.videocam));
      await tester.pumpAndSettle();
      expect(f.wire['video'], isFalse);
      permission.complete({Permission.camera.value: 1});
      await tester.pumpAndSettle();
      expect(
        f.platform.controller.scripts,
        isNot(contains('setDevice("video", false)')),
      );
      expect(f.platform.controller.scripts, contains('pauseMedia()'));
      expect(f.platform.controller.loads, 1);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'home listening remains connected when both own capture devices are off',
    (tester) async {
      const channel = MethodChannel('flutter.baseflow.com/permissions/methods');
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        if (call.method == 'requestPermissions') {
          return {
            for (final value in List<int>.from(call.arguments as List))
              value: 1,
          };
        }
        return 1;
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );
      final f = _MediaHarness()..home = true;
      await f.pump(tester);
      await f.emit(tester, 'joined');
      await tester.tap(find.byIcon(Icons.videocam_off));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.videocam));
      await tester.pumpAndSettle();
      expect(
        f.platform.controller.scripts,
        contains('setDevice("video", true)'),
      );
      expect(f.platform.controller.scripts, isNot(contains('pauseMedia()')));
      expect(f.passes, 1);
      expect(f.platform.controller.loads, 1);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'teacher start and permission failure keep the native board mounted and polling',
    (tester) async {
      final requests = <List<int>>[];
      const channel = MethodChannel('flutter.baseflow.com/permissions/methods');
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        if (call.method == 'requestPermissions') {
          final values = List<int>.from(call.arguments as List);
          requests.add(values);
          return {for (final value in values) value: 1};
        }
        return 1;
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );
      final f = _MediaHarness();
      await f.pump(tester);
      final board = tester.element(find.byType(InAppWebView));
      expect(f.passes, 0);
      await f.teacher(tester, 'video', true);
      expect(f.passes, 1);
      expect(
        f.platform.controller.scripts.any((s) => s.startsWith('join(')),
        isTrue,
      );
      await f.emit(tester, 'joined');
      expect(requests, [
        [Permission.camera.value],
      ]);
      await f.emit(tester, 'camera-failed', 'denied');
      expect(f.platform.controller.scripts, contains('pauseMedia()'));
      expect(tester.element(find.byType(InAppWebView)), same(board));
      final before = f.boards;
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(f.boards, greaterThan(before));
      expect(f.platform.controller.loads, 1);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'cancelled call-pass reply never joins and does not reload the native board',
    (tester) async {
      final pending = Completer<LessonCallPassOutcome>();
      final f = _MediaHarness()..pass = () => pending.future;
      await f.pump(tester);
      await f.teacher(tester, 'video', true);
      expect(f.passes, 1);
      await f.teacher(tester, 'video', false);
      pending.complete(
        const LessonCallPassOutcome.pass(
          LessonCallPass(
            displayName: 'Test',
            domain: 'meet.example.com',
            jwt: 'synthetic',
            room: 'lesson',
            xmppDomain: 'meet.example.com',
            workspaceFormat: 'board',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        f.platform.controller.scripts.any((s) => s.startsWith('join(')),
        isFalse,
      );
      expect(f.platform.controller.loads, 1);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'a home pupil still has a board when the video service is unavailable',
    (tester) async {
      final f = _MediaHarness()
        ..home = true
        ..pass = () async =>
            throw KioskApiException('Unavailable', code: 'not_configured');
      await f.pump(tester);
      expect(f.passes, 1);
      expect(find.byType(InAppWebView), findsOneWidget);
      expect(
        f.platform.controller.scripts.any(
          (s) => s.startsWith('openWorkspace('),
        ),
        isTrue,
      );
      final before = f.boards;
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(f.boards, greaterThan(before));
      await tester.pumpWidget(const SizedBox());
    },
  );
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
                fetchPass: (_, {String? assignment}) async {
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
