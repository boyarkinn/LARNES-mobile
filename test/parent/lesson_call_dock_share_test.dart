import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/features/parent/widgets/lesson_call_dock.dart';
import 'package:larnes_mobile/l10n/app_localizations.dart';

void main() {
  testWidgets('does not offer sending the phone screen', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ru'),
        home: Scaffold(
          body: LessonCallDock(
            audioOn: true,
            callReady: true,
            cameraNote: null,
            canRetry: true,
            closed: false,
            connectFailed: false,
            hearBlocked: false,
            lost: false,
            micNote: null,
            onHear: () {},
            onLeave: () {},
            onRetry: () {},
            onToggleAudio: () {},
            onToggleVideo: () {},
            reconnecting: false,
            videoOn: true,
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.screen_share), findsNothing);
    expect(find.bySemanticsLabel('Показать экран'), findsNothing);
    expect(find.byIcon(Icons.videocam), findsOneWidget);
    expect(find.byIcon(Icons.mic), findsOneWidget);
  });
}
