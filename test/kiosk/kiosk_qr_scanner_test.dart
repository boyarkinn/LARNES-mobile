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
}
