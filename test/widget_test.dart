import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/app/theme/larnes_theme.dart';

void main() {
  testWidgets('Larnes theme builds app shell', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLarnesTheme(),
        home: const Scaffold(
          body: Center(child: Text('LARNES')),
        ),
      ),
    );

    expect(find.text('LARNES'), findsOneWidget);
  });
}
