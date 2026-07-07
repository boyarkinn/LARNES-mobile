import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/features/kiosk/widgets/kiosk_qr_scanner.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';

void main() {
  testWidgets('mock scanner invokes onScan with token', (tester) async {
    String? scannedToken;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ru'),
        home: Scaffold(
          body: KioskQrScanner(
            mockScanEnabled: true,
            mockScanToken: 'qr-token-value',
            onScan: (token) async {
              scannedToken = token;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Включить камеру'));
    await tester.pumpAndSettle();

    expect(scannedToken, 'qr-token-value');
  });

  testWidgets('mock scanner shows external error', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ru'),
        home: Scaffold(
          body: KioskQrScanner(
            mockScanEnabled: true,
            externalError: 'QR-код отозван. Попросите родителя обновить код.',
            onScan: (_) async {},
          ),
        ),
      ),
    );

    expect(find.textContaining('QR-код отозван'), findsOneWidget);
  });

  testWidgets('preview for test shows flip camera button', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ru'),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              child: KioskQrScanner(
                previewForTest: true,
                onScan: (_) async {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byTooltip('Сменить камеру'), findsOneWidget);
  });

  testWidgets('flip camera tap is safe in preview for test', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ru'),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              child: KioskQrScanner(
                previewForTest: true,
                onScan: (_) async {},
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.cameraswitch));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Сменить камеру'), findsOneWidget);
  });
}
