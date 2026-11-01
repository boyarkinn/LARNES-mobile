import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/features/messenger/message_notice_card.dart';

void main() {
  testWidgets('short preview is balanced and close icon is centered', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 360,
              child: MessageNoticeCard(
                author: 'ЧИП',
                text: 'ТЕСТ2',
                closeLabel: 'Закрыть',
                onOpen: () {},
                onClose: () {},
              ),
            ),
          ),
        ),
      ),
    );
    final open = tester.getRect(find.byType(InkWell).first);
    final avatar = tester.getRect(find.byType(CircleAvatar));
    expect(avatar.width, 64);
    expect(avatar.top - open.top, closeTo(open.bottom - avatar.bottom, .5));
    final button = tester.getRect(find.byType(IconButton));
    final icon = tester.getRect(find.byIcon(Icons.close));
    expect(icon.center.dx, closeTo(button.center.dx, .5));
    expect(icon.center.dy, closeTo(button.center.dy, .5));
  });
  for (final brightness in Brightness.values) {
    testWidgets(
      'notification readable in $brightness at narrow width and larger text',
      (tester) async {
        var opened = 0, closed = 0;
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(brightness: brightness),
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 280,
                  child: MediaQuery(
                    data: const MediaQueryData(
                      textScaler: TextScaler.linear(1.6),
                    ),
                    child: MessageNoticeCard(
                      author: 'Анна Иванова',
                      text:
                          'Очень длинное сообщение с уточнением домашнего задания',
                      closeLabel: 'Закрыть',
                      onOpen: () => opened++,
                      onClose: () => closed++,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        final avatar = tester.getRect(find.byType(CircleAvatar)),
            name = tester.getRect(find.text('Анна Иванова')),
            text = tester.getRect(
              find.text(
                'Очень длинное сообщение с уточнением домашнего задания',
              ),
            );
        expect(avatar.right, lessThan(name.left));
        expect(name.bottom, lessThanOrEqualTo(text.top));
        final nameWidget = tester.widget<Text>(find.text('Анна Иванова'));
        expect(
          nameWidget.style?.color,
          brightness == Brightness.dark
              ? const Color(0xFFEEF1F5)
              : const Color(0xFF171B24),
        );
        await tester.tap(find.byTooltip('Закрыть'));
        expect(closed, 1);
        expect(opened, 0);
        await tester.tap(find.text('Анна Иванова'));
        expect(opened, 1);
      },
    );
  }
}
