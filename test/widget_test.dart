import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/app/app.dart';

void main() {
  testWidgets('App boots', (WidgetTester tester) async {
    await tester.pumpWidget(const LarnesApp());
    expect(find.text('LARNES'), findsWidgets);
  });
}
