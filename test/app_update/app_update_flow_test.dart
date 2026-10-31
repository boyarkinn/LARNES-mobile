import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/core/app_update/app_update_controller.dart';
import 'package:larnes_mobile/core/app_update/app_update_dialog.dart';
import 'package:larnes_mobile/core/app_update/app_update_info.dart';
import 'package:larnes_mobile/core/app_update/app_update_service.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';

Future<void> snapshot(WidgetTester tester, String name) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('update-preview')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await File(
      'build/app-update-$name.png',
    ).writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

class UpdateService extends AppUpdateService {
  final download = Completer<String>();
  final verification = Completer<void>();
  void Function(int, int?)? progress;
  CancelToken? cancel;
  int downloads = 0, installs = 0, checks = 0;
  @override
  Future<bool> get isAndroidPlatform async => true;
  @override
  Future<String> readLocalVersionLabel() async => '1.0.10 (12)';
  @override
  Future<AppUpdateInfo?> fetchAvailableUpdate() async {
    checks++;
    return const AppUpdateInfo(
      releaseNotes: null,
      sha256: 'hash',
      url: 'https://larnes.test/update.apk',
      versionCode: 13,
      versionName: '1.0.11',
    );
  }

  @override
  Future<String> downloadApk({
    required AppUpdateInfo update,
    void Function(int, int?)? onProgress,
    CancelToken? cancelToken,
  }) {
    downloads++;
    progress = onProgress;
    cancel = cancelToken;
    cancelToken?.whenCancel.then((error) {
      if (!download.isCompleted) download.completeError(error);
    });
    return download.future;
  }

  @override
  Future<void> verifySha256({
    required String filePath,
    required String expectedSha256,
  }) => verification.future;
  @override
  Future<void> openInstaller(String filePath) async {
    installs++;
  }
}

void main() {
  test(
    'one download owns progress, checking cannot reset it, install retry reuses the file',
    () async {
      final service = UpdateService();
      final owner = AppUpdateController(service: service);
      await owner.checkForUpdate();
      final first = owner.downloadAndInstall(
        onProgress: (_) {},
        onError: (_) {
          fail('unexpected failure');
        },
      );
      await owner.downloadAndInstall(onProgress: (_) {}, onError: (_) {});
      await owner.checkForUpdate();
      expect(service.downloads, 1);
      expect(service.checks, 1);
      service.progress!(42, 100);
      expect(owner.downloadProgress, .42);
      expect(owner.receivedBytes, 42);
      service.download.complete('/update.apk');
      await Future<void>.delayed(Duration.zero);
      expect(owner.status, AppUpdateStatus.verifying);
      service.verification.complete();
      await first;
      expect(owner.status, AppUpdateStatus.installerReady);
      expect(service.installs, 1);
      await owner.downloadAndInstall(onProgress: (_) {}, onError: (_) {});
      expect(service.downloads, 1);
      expect(service.installs, 2);
      owner.dispose();
    },
  );
  testWidgets(
    'the offer visibly advances, shows verification, and separates Android installation',
    (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.runAsync(() async {
        final font = File(
          '${Platform.environment['WINDIR'] ?? 'C:/Windows'}/Fonts/arial.ttf',
        );
        if (await font.exists()) {
          final loader = FontLoader('Roboto')
            ..addFont(
              Future.value(ByteData.sublistView(await font.readAsBytes())),
            );
          await loader.load();
        }
      });
      final service = UpdateService();
      final controller = AppUpdateController(service: service);
      await controller.checkForUpdate();
      await tester.pumpWidget(
        RepaintBoundary(
          key: const ValueKey('update-preview'),
          child: MaterialApp(
            locale: const Locale('ru'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () =>
                      showAppUpdateDialog(context, controller: controller),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await snapshot(tester, 'offer');
      expect(find.text('Скачайте обновление 1.0.11'), findsOneWidget);
      await tester.tap(find.text('Скачать'));
      await tester.pump();
      service.progress!(42 * 1024 * 1024, 100 * 1024 * 1024);
      await tester.pump();
      expect(find.text('42%'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 300));
      await snapshot(tester, 'download');
      expect(find.text('42.0 / 100.0 МБ'), findsOneWidget);
      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byType(LinearProgressIndicator),
            )
            .value,
        .42,
      );
      service.download.complete('/update.apk');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      expect(controller.status, AppUpdateStatus.verifying);
      expect(find.text('Проверяем файл…'), findsOneWidget);
      service.verification.complete();
      await tester.pumpAndSettle();
      await snapshot(tester, 'install');
      expect(
        find.text('Подтвердите установку в окне Android.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Установить'));
      await tester.pumpAndSettle();
      expect(service.downloads, 1);
      expect(service.installs, 2);
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
    },
  );
  testWidgets(
    'unknown file length shows bytes and animated progress, never a fake percentage',
    (tester) async {
      final service = UpdateService();
      final owner = AppUpdateController(service: service);
      await owner.checkForUpdate();
      final job = owner.downloadAndInstall(onProgress: (_) {}, onError: (_) {});
      service.progress!(1024 * 1024, -1);
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: AppUpdateProgress(controller: owner)),
        ),
      );
      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byType(LinearProgressIndicator),
            )
            .value,
        isNull,
      );
      expect(find.text('1.0 МБ'), findsOneWidget);
      owner.cancelDownload();
      await job;
      expect(owner.status, AppUpdateStatus.available);
      await tester.pumpWidget(const SizedBox());
      owner.dispose();
    },
  );
  testWidgets('download failure is visible inside the update offer', (
    tester,
  ) async {
    final service = UpdateService();
    final controller = AppUpdateController(service: service);
    await controller.checkForUpdate();
    final job = controller.downloadAndInstall(
      onProgress: (_) {},
      onError: (_) {},
    );
    service.download.completeError(Exception('network'));
    await job;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: AppUpdateProgress(controller: controller)),
      ),
    );
    expect(
      find.text('Не удалось обновить. Попробуйте ещё раз.'),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });
  test(
    'streamed checksum accepts intact files and rejects a truncated APK',
    () async {
      final dir = await Directory.systemTemp.createTemp('larnes-update-test-');
      try {
        final file = File('${dir.path}/sample.apk');
        final bytes = List<int>.generate(1024 * 1024, (i) => i % 256);
        await file.writeAsBytes(bytes);
        final service = AppUpdateService();
        final digest = sha256.convert(bytes).toString();
        await service.verifySha256(filePath: file.path, expectedSha256: digest);
        await file.writeAsBytes(bytes.sublist(0, 1024));
        await expectLater(
          service.verifySha256(filePath: file.path, expectedSha256: digest),
          throwsA(isA<AppUpdateVerificationException>()),
        );
      } finally {
        await dir.delete(recursive: true);
      }
    },
  );
}
